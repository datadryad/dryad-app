#!/usr/bin/env ruby

require 'set'
require 'stash/wrapper'

ST = Stash::Wrapper

# ------------------------------------------------------------
# Generate Stash wrapper

# ------------------------------------------------------------
# Generate datacite metadata

def datacite(doi:, creator:, title:, publisher:, pubyear:, subjects:, resource_type:, abstract:)
  xml_text = "<dcs:resource xmlns:dcs='http://datacite.org/schema/kernel-3'
                            xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
                            xsi:schemaLocation='http://datacite.org/schema/kernel-3
                            http://schema.datacite.org/meta/kernel-3/metadata.xsd'>
                <dcs:identifier identifierType='DOI'>#{doi}</dcs:identifier>
                <dcs:creators>
                  <dcs:creator>
                    <dcs:creatorName>#{creator}</dcs:creatorName>
                  </dcs:creator>
                </dcs:creators>
                <dcs:titles>
                  <dcs:title>#{title}</dcs:title>
                </dcs:titles>
                <dcs:publisher>#{publisher}</dcs:publisher>
                <dcs:publicationYear>#{pubyear}</dcs:publicationYear>
                <dcs:subjects>
                  #{(subjects.map {|s| "<dcs:subject>#{s}</dcs:subject>"}).join("\n")}
                </dcs:subjects>
                <dcs:resourceType resourceTypeGeneral='Dataset'>#{resource_type}</dcs:resourceType>
                <dcs:descriptions>
                  <dcs:description descriptionType='Abstract'>#{abstract}</dcs:description>
                </dcs:descriptions>
              </dcs:resource>"
  REXML::Document.new(xml_text).root
end

# ------------------------------------------------------------
# Main

def main
  count = 1 + ARGV[1].to_i
  (1..count).each do |i|
    formatter = REXML::Formatters::Pretty.new
    formatter.compact = true

    dcs = datacite(
        doi: '1/2',
        creator: 'elvis',
        title: 'presley',
        publisher: 'graceland',
        pubyear: 1976,
        subjects: ['elvis', 'priscilla'],
        resource_type: 'single',
        abstract: 'blue suede shoes'
    )

    puts formatter.write(dcs, '')
  end
end

# ------------------------------------------------------------
# Sample text

@text = "Quo usque tandem abutere, Catilina, patientia nostra? Quam diu etiam furor iste tuus nos eludet? Quem ad finem sese effrenata iactabit audacia? Nihil ne te nocturnum praesidium Palati, nihil urbis vigiliae, nihil timor populi, nihil concursus bonorum omnium, nihil hic munitissimus habendi senatus locus, nihil horum ora voltusque moverunt? Patere tua consilia non sentis, constrictam iam horum omnium scientia teneri coniurationem tuam non vides? Quid proxima, quid superiore nocte egeris, ubi fueris, quos convocaveris, quid consilii ceperis, quem nostrum ignorare arbitraris? O tempora, o mores! Senatus haec intellegit. Consul videt; hic tamen vivit. Vivit? immo vero etiam in senatum venit, fit publici consilii particeps, notat et designat oculis ad caedem unum quemque nostrum. Nos autem fortes viri satisfacere rei publicae videmur, si istius furorem ac tela vitemus. Ad mortem te, Catilina, duci iussu consulis iam pridem oportebat, in te conferri pestem, quam tu in nos omnes iam diu machinaris. An vero vir amplissumus, Scipio, pontifex maximus, Gracchum mediocriter labefactantem statum rei publicae privatus interfecit; Catilinam orbem terrae caede atque incendiis vastare cupientem nos consules perferemus? Nam illa nimis antiqua praetereo, quod Servilius Ahala Maelium novis rebus studentem manu sua occidit. Fuit, fuit ista quondam in hac re publica virtus, ut viri fortes acrioribus suppliciis civem perniciosum quam acerbissimum hostem coercerent. Habemus senatus consultum in te, Catilina, vehemens et grave, non deest rei publicae consilium neque auctoritas huius ordinis; nos, nos, dico aperte, consules desumus. Decrevit quondam senatus, ut Opimius consul videret, ne quid res publica detrimenti caperet; nox nulla intercessit; interfectus est propter quasdam seditionum suspiciones Gracchus, clarissimo patre, avo, maioribus, occisus est cum liberis Fulvius consularis. Simili senatus consulto Mario et Valerio consulibus est permissa res publica; num unum diem postea Saturninum tribunum et Servilium praetorem mors ac rei publicae poena remorata est? At vero nos vicesimum iam diem patimur hebescere aciem horum auctoritatis. Habemus enim huiusce modi senatus consultum, verum inclusum in tabulis tamquam in vagina reconditum, quo ex senatus consulto confestim te interfectum esse, Catilina, convenit. Vivis, et vivis non ad deponendam, sed ad confirmandam audaciam. Cupio, patres conscripti, me esse clementem, cupio in tantis rei publicae periculis me non dissolutum videri, sed iam me ipse inertiae nequitiaeque condemno. Castra sunt in Italia contra populum Romanum in Etruriae faucibus conlocata, crescit in dies singulos hostium numerus; eorum autem castrorum imperatorem ducemque hostium intra moenia atque adeo in senatu videmus intestinam aliquam cotidie perniciem rei publicae molientem. Si te iam, Catilina, comprehendi, si interfici iussero, credo, erit verendum mihi, ne non potius hoc omnes boni serius a me quam quisquam crudelius factum esse dicat. Verum ego hoc, quod iam pridem factum esse oportuit, certa de causa nondum adducor ut faciam. Tum denique interficiere, cum iam nemo tam inprobus, tam perditus, tam tui similis inveniri poterit, qui id non iure factum esse fateatur. Quamdiu quisquam erit, qui te defendere audeat, vives, et vives ita, ut nunc vivis. multis meis et firmis praesidiis obsessus, ne commovere te contra rem publicam possis. Multorum te etiam oculi et aures non sentientem, sicut adhuc fecerunt, speculabuntur atque custodient. Etenim quid est, Catilina, quod iam amplius expectes, si neque nox tenebris obscurare coeptus nefarios nec privata domus parietibus continere voces coniurationis tuae potest, si illustrantur, si erumpunt omnia? Muta iam istam mentem, mihi crede, obliviscere caedis atque incendiorum. Teneris undique; luce sunt clariora nobis tua consilia omnia; quae iam mecum licet recognoscas. Meministine me ante diem XII Kalendas Novembris dicere in senatu fore in armis certo die, qui dies futurus esset ante diem VI Kal. Novembris, Manlium, audaciae satellitem atque administrum tuae? Num me fefellit, Catilina, non modo res tanta, tam atrox tamque incredibilis, verum, id quod multo magis est admirandum, dies? Dixi ego idem in senatu caedem te optumatium contulisse in ante diem V Kalendas Novembris, tum cum multi principes civitatis Roma non tam sui conservandi quam tuorum consiliorum reprimendorum causa profugerunt. Num infitiari potes te illo ipso die meis praesidiis, mea diligentia circumclusum commovere te contra rem publicam non potuisse, cum tu discessu ceterorum nostra tamen, qui remansissemus, caede te contentum esse dicebas? Quid? cum te Praeneste Kalendis ipsis Novembribus occupaturum nocturno impetu esse confideres, sensistin illam coloniam meo iussu meis praesidiis, custodiis, vigiliis esse munitam? Nihil agis, nihil moliris, nihil cogitas, quod non ego non modo audiam, sed etiam videam planeque sentiam. Recognosce tandem mecum noctem illam superiorem; iam intelleges multo me vigilare acrius ad salutem quam te ad perniciem rei publicae. Dico te priore nocte venisse inter falcarios--non agam obscure--in Laecae domum; convenisse eodem complures eiusdem amentiae scelerisque socios. Num negare audes? quid taces? Convincam, si negas. Video enim esse hic in senatu quosdam, qui tecum una fuerunt. O di inmortales! ubinam gentium sumus? in qua urbe vivimus? quam rem publicam habemus? Hic, hic sunt in nostro numero, patres conscripti, in hoc orbis terrae sanctissimo gravissimoque consilio, qui de nostro omnium interitu, qui de huius urbis atque adeo de orbis terrarum exitio cogitent! Hos ego video consul et de re publica sententiam rogo et, quos ferro trucidari oportebat, eos nondum voce volnero! Fuisti igitur apud Laecam illa nocte, Catilina, distribuisti partes Italiae, statuisti, quo quemque proficisci placeret, delegisti, quos Romae relinqueres, quos tecum educeres, discripsisti urbis partes ad incendia, confirmasti te ipsum iam esse exiturum, dixisti paulum tibi esse etiam nunc morae, quod ego viverem. Reperti sunt duo equites Romani, qui te ista cura liberarent et sese illa ipsa nocte paulo ante lucem me in meo lectulo interfecturos esse pollicerentur."
@words = @text.split(" ")
@words_plain = @words.map {|t| t.tr( '^A-Za-z', '' )}.select {|w| w.length > 1}
@words_unique = @words_plain.map {|w| w.downcase }.to_set.to_a.sort!
@letters = (97..122).map { |c| c.chr }

def take(list, start, len)
  start = start % list.length
  slice = list.slice(start, list.length - start).to_a
  taken = slice.take(len)
  if taken.length < len
    taken + take(list, start + taken.length, len - taken.length)
  else
    taken
  end
end

def take_sublist(list, len)
  start = rand(list.length)
  take(list, start, len)
end

def take_random(list, count)
  set = Set.new
  while set.size < count
    set << list[rand(list.length)]
  end
  set.to_a.sort!
end

def random_text(word_count)
  text = take_sublist(@words, word_count).join(" ").capitalize
  while text.match /[^a-z]$/
    text = text.slice(0, text.length - 1)
  end
  text
end

def random_sentence(word_count)
  text = random_text(word_count)
  end_index = text =~ /[.?!-]/ || (text.length - 1)
  text.slice(0, end_index)
end

def random_words(count)
  (0...count).map { |i| random_from(@words_unique) }
end

def less_than(max)
  num = ((0...max).inject { |sum, i| sum + rand.round })
  num >= 1 ? num : 1
end

def much_less_than(max)
  num = ((0...max).inject { |sum, i| sum + (rand * rand).round })
  num >= 1 ? num : 1
end

def random_names(max)
  num_names = much_less_than max
  (0...num_names).map { |i| random_name }
end

def random_name
  names = less_than(4)
  names = 2 if names < 2
  random_words(names).map { |w| w.capitalize }.join(" ")
end

def random_from(list)
  list[rand(0...list.length)]
end

@authors = (0...1000).map { |i| random_name }
@publishers = (0...100).map { |i| random_names(10).join(" ")}
@resource_types = (0...20).map { |i| random_names(3).join(" ") }

# ------------------------------------------------------------
# Random sample fields

def doi(index)
  prefix = take_sublist(@letters, 3).join
  registrant = 20000+less_than(10000)
  "10.#{registrant}/#{prefix}#{1000000 + index}"
end

def creators
  num_authors = less_than(10)
  (0...num_authors).map { |i| random_from(@authors)}
end

def title
  loop do
    title = random_sentence(much_less_than(100))
    return title if title.length > 10
  end
end

def publisher
  random_from(@publishers)
end

def pub_year
  2000 + rand(15)
end

def subjects
  num_keywords = much_less_than 20
  take_random(@words_unique, num_keywords)
end

def resource_type
  random_from(@resource_types)
end

def abstract
  random_text(much_less_than(500)) + "."
end

# ------------------------------------------------------------
# Invocation of main

(0..100).each do |i|
  doi = doi(i)
  puts "#{doi}\t#{resource_type}"
end

# main

