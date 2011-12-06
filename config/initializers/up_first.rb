class String
	def up_first
		self.downcase!
		self[0] = self.first.upcase
		return self
	end
end

class Numeric
  def humanize(rounding=2,delimiter=' ',separator=',')
    value = respond_to?(:round_with_precision) ? round(rounding) : self

    #see number with delimeter
    parts = value.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
    parts.join separator
  end
end

class NilClass
  def titlecase
    return self.to_s
  end
  
  def up_first
    return self.to_s
  end
end