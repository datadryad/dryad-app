module LatestHelper

  # reverses name and puts last, first middle, etc
  def name_reverser(name)
    return '[Name not set]' if name.blank?

    name_split = name.delete(',').split
    return name if name_split.length < 2

    "#{name_split.last} #{name_split[0..-2].join(' ')}"
  end

end
