import {sentenceCase} from '../../../app/javascript/lib/sentence-case';

const keepers = [
  'Occurrence dataset for Iranian Lepidoptera (Geometridae, Lycaenidae and Zygaenidsae)',
  "(3R)-hydroxymyristoyl-ACP dehydratase is a great title isn't-it-just",
  'mRNAs are really cool',
  'Why would anyone name their kid something like XYZ123',
  'X2a3b contributes to stuff in the cell',
  'The title should be a succinct summary of the data and its purpose or use',
  'The absolutely true story about how I found a frog',
  'my_manuscript is_submitted to a journal',
  'XYZ this is my title',
  'Flower visitors and pollen',
  'The first proteomic database for this type of research (PDTR)'
]

describe('sentenceCase', () => {
  it('sentence cases correctly', () => {
    expect(sentenceCase('Occurrence Dataset for Iranian Lepidoptera (Geometridae, Lycaenidae and Zygaenidsae)')).toBe(keepers[0])
    expect(sentenceCase("(3R)-hydroxymyristoyl-ACP dehydratase Is A Great Title Isn't-It-Just")).toBe(keepers[1])
    expect(sentenceCase('mRNAs Are Really Cool')).toBe(keepers[2])
    expect(sentenceCase('why would Anyone Name Their Kid something like XYZ123')).toBe(keepers[3])
    expect(sentenceCase('Why Would Anyone Name Their Kid Something Like XYZ123')).toBe(keepers[3])
    expect(sentenceCase('X2a3b CONTRIBUTES TO STUFF IN THE CELL')).toBe(keepers[4])
  })
  it('keeps casing when correct', () => {
    keepers.forEach(s => {
      expect(sentenceCase(s)).toBe(s)
    })
  })
  it('suggests reasonable casing for all-case examples', () => {
    const allcase = [
      'FIRST SECOND THIRD ONE TWO THREE TEST TESTING',
      'XYZ THIS IS MY TITLE',
      'data for my paper',
      'data data data data data',
      'data data data data set',
      'data set for my data',
      'this is my title',
      'this is the title for my dataset',
      'data for my paper in journal',
      'xyz this is my title'
    ]
    allcase.forEach(s => {
      expect(sentenceCase(s)).toBe(s.toLowerCase('en-US').replace(/^\p{CWU}/u, char => char.toLocaleUpperCase('en-US')))
    })
  })
})