require 'db_spec_helper'

module StashEngine

  describe Organization do

    before(:each) do
      @organization = Organization.create(
        identifier: 'https://example.org/12345',
        name: 'Test Organization',
        country: 'East Timor'
      )
    end

    it 'defaults to candidate == false' do
      expect(@organization.candidate?).to eql(false)
    end

    describe :validations do

      before(:each) do
        @org2 = Organization.new(identifier: 'https://example.org/123456', name: 'Another Test Organization')
      end

      describe :identifier do

        it 'must be unique' do
          expect(@org2.save).to eql(true)
          expect(@org2.errors.count).to eql(0)

          @org2.identifier = @organization.identifier
          expect(@org2.save).to eql(false)
          expect(@org2.errors.count).to eql(1)
          expect(@org2.errors[:identifier].first).to eql('has already been taken')
        end

        it 'can be nil' do
          @organization.identifier = nil
          expect(@organization.save).to eql(true)
          expect(@organization.errors.count).to eql(0)
        end

      end

      describe :name do

        it 'must be unique' do
          expect(@org2.save).to eql(true)
          expect(@org2.errors.count).to eql(0)

          @org2.name = @organization.name
          expect(@org2.save).to eql(false)
          expect(@org2.errors.count).to eql(1)
          expect(@org2.errors[:name].first).to eql('has already been taken')
        end

        it 'cannot be nil' do
          @organization.name = nil
          expect(@organization.save).to eql(false)
          expect(@organization.errors.count).to eql(1)
          expect(@organization.errors[:name].first).to eql('can\'t be blank')
        end

      end

    end

    describe :acronyms do

      it 'can accept/return an Array' do
        @organization.acronyms = %w[A B C]
        expect(@organization.save).to eql(true)
        expect(@organization.acronyms.is_a?(Array)).to eql(true)
      end

    end

    describe :aliases do

      it 'can accept/return an Array' do
        @organization.aliases = %w[A B C]
        expect(@organization.save).to eql(true)
        expect(@organization.aliases.is_a?(Array)).to eql(true)
      end

    end

    describe :name_with_acronym do

      it 'returns the name only if there are no acronyms' do
        expect(@organization.name_with_acronym).to eql(@organization.name)
      end

      it 'appends the 1st acronym to the name' do
        @organization.update(acronyms: %w[A B])
        expect(@organization.name_with_acronym).to eql("#{@organization.name} (A)")
        @organization.update(acronyms: %w[B A])
        expect(@organization.name_with_acronym).to eql("#{@organization.name} (B)")
      end

    end

    describe :fee_waiver_country? do

      it 'returns true if the country is listed in the config' do
        @organization.country = APP_CONFIG.fee_waiver_countries.first
        expect(@organization.fee_waiver_country?).to eql(true)
      end

      it 'returns false if the country is NOT listed in the config' do
        @organization.country = 'Foo'
        expect(@organization.fee_waiver_country?).to eql(false)
      end

    end

    describe :search do

      before(:each) do
        @organization.update(acronyms: %w[Foo Bar], aliases: %w[Lorem Ipsum])
      end

      it 'finds an organization by name' do
        expect(Organization.search(@organization.name).first).to eql(@organization)
        expect(Organization.search('Test').first).to eql(@organization)
      end

      it 'finds an organization by acronym' do
        expect(Organization.search('Foo').first).to eql(@organization)
        expect(Organization.search('Bar').first).to eql(@organization)
      end

      it 'finds an organization by alias' do
        expect(Organization.search('Lorem').first).to eql(@organization)
        expect(Organization.search('Ipsum').first).to eql(@organization)
      end


    end

  end

end