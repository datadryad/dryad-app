# require the items for the notifier
Dir[File.join(__dir__, '..', '..', 'app', '*.rb')].each { |file| require file }
require 'ostruct'
class CollectionSetSpec
  describe 'collection_set' do

    before(:each) do
      @name = 'cdl_dryad'
      @opts =
        { last_retrieved: '2019-01-23T00:41:43Z',
          retry_status_update:
         [{ doi: '1245/6332', merritt_id: 'http://n2t.net/klj/2344', version: '1', time: '2019-01-21T04:43:19Z' },
          { doi: '348574/38483', merritt_id: 'http://n2t.net/klksj/843', version: '2', time: '2019-01-07T23:59:39Z' }] }
      @collection_set = CollectionSet.new(name: @name, settings: @opts)

      logger = double('logger')
      allow(logger).to receive(:info)
      allow(logger).to receive(:error)
      allow(Config).to receive(:logger).and_return(logger)
    end

    describe '#initialize' do
      it 'initializes with correct name' do
        expect(@name).to eql(@collection_set.name)
      end

      it 'stores the correct time' do
        expect(Time.iso8601(@opts[:last_retrieved])).to eql(@collection_set.last_retrieved)
      end

      it 'retry list set correctly' do
        # the arrays should be the same and subtracting makes them zero length
        expect((@opts[:retry_status_update] - @collection_set.retry_list).length).to eql(0)
      end
    end

    describe '#retry_errored_dryad_notifications' do
      before(:each) do
        @notif = double('notifier')
      end

      it 'retries errored notifications successfully with state changes' do
        allow(@notif).to receive(:notify).and_return(true)
        allow(DryadNotifier).to receive(:new).and_return(@notif)

        @collection_set.retry_errored_dryad_notifications
        expect(@collection_set.retry_list).to eql([])
      end

      it 'retries errored notifications unsuccessfully with no state changes' do
        allow(@notif).to receive(:notify).and_return(false)
        allow(DryadNotifier).to receive(:new).and_return(@notif)

        @collection_set.retry_errored_dryad_notifications
        expect(@collection_set.retry_list).to eql(@opts[:retry_status_update])
      end
    end

    describe '#notify_dryad' do
      before(:each) do
        @one = OpenStruct.new('deleted?' => true,
                              timestamp: Time.new(2019, 0o2, 1).utc,
                              doi: '12/xu',
                              merritt_id: 'http://n2t.net/34/yv',
                              version: '1')

        @two = OpenStruct.new('deleted?' => false,
                              timestamp: Time.new(2019, 0o2, 2).utc,
                              doi: '88/yum',
                              merritt_id: 'http://n2t.net/66/qu',
                              version: '2')

        @three = OpenStruct.new('deleted?' => false,
                                timestamp: Time.new(2019, 0o2, 3).utc,
                                doi: '66/quack',
                                merritt_id: 'http://n2t.net/55/zop',
                                version: '1')

        allow(DatasetRecord).to receive(:find).and_return([@one, @two, @three])

        @notif = double('notifier')
      end

      it 'updates the last retrieved' do
        allow(@notif).to receive(:notify).and_return(true)
        allow(DryadNotifier).to receive(:new).and_return(@notif)
        @collection_set.notify_dryad
        expect(@collection_set.last_retrieved).to eql(@three.timestamp)
      end

      it 'adds failed notifications to the retry list' do
        allow(@notif).to receive(:notify).and_return(false)
        allow(DryadNotifier).to receive(:new).and_return(@notif)
        @collection_set.notify_dryad
        expect(@collection_set.retry_list.length).to eql(4)
      end
    end

    describe '#dois_to_retry' do
      it 'gives list of dois' do
        expect(@collection_set.dois_to_retry).to eql(@opts[:retry_status_update].map { |i| i[:doi] })
      end
    end

    describe '#add_retry_item' do

      before(:each) do
        @time = Time.new.utc
        @collection_set.add_retry_item(doi: 'sn00/R0ck', merritt_id: 'http://nt2.net/g3n48', version: '3')
      end

      it 'adds item to the list' do
        expect(@collection_set.retry_list.length).to eq(3)
      end

      it 'sets timestamp to be about now' do
        l = @collection_set.retry_list.last
        t = Time.iso8601(l[:time])
        expect(@time).to be_within(10.seconds).of(t)
      end

      it 'sets doi, merritt_id and version' do
        l = @collection_set.retry_list.last
        expect(l[:doi]).to eql('sn00/R0ck')
        expect(l[:merritt_id]).to eql('http://nt2.net/g3n48')
        expect(l[:version]).to eql('3')
      end
    end

    describe '#remove_retry_item' do
      it 'removes the doi that is specified' do
        @collection_set.remove_retry_item(doi: @opts[:retry_status_update].first[:doi])
        expect(@collection_set.retry_list.length).to eql(1)
      end
    end

    describe '#clean_retry_items!' do
      it 'removes items older than n days' do
        @collection_set.clean_retry_items!(days: 1)
        expect(@collection_set.retry_list.length).to eql(0)
      end
    end

    describe '#hash_serialized' do
      it 'creates the correct retrieved date' do
        hsh = @collection_set.hash_serialized
        expect(hsh[:last_retrieved]).to eq(@opts[:last_retrieved])
      end

      it 'creates the correct retry hash' do
        hsh = @collection_set.hash_serialized
        expect(@opts[:retry_status_update]).to eq(hsh[:retry_status_update])
      end
    end

    describe '#retry_list' do
      it 'is the same hash going in and out' do
        expect(@opts[:retry_status_update]).to eq(@collection_set.retry_list)
      end
    end
  end
end
