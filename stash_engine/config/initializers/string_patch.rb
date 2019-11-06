# open class modified to add elipses to center of string for specific length string for display
class String
  def ellipsisize(len = 20)
    return self if length <= len
    "#{self[0..(len / 2)]}...#{self[(-len / 2)..-1]}"
  end
end
