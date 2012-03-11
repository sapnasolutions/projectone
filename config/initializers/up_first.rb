class String
	def up_first
		self.downcase!
		self[0] = self.first.upcase
		return self
	end
	
  def to_slug
    silence_warnings {
		str = Unicode.normalize_KD(self).gsub(/[^\x00-\x7F]/n,'')
		str = str.gsub(/\W+/, '-').gsub(/^-+/,'').gsub(/-+$/,'').downcase
	}
  end
  
  def format_research
    self.downcase.to_slug
  end
	
  def count_enum value=0
    value.to_s + ' ' + ((value > 1) ? self.pluralize : self)
  end
  
  # Kill accent (and all special Chars, so be careful)
  def pretty_url
    Iconv.iconv("ASCII//IGNORE//TRANSLIT", "UTF-8", self).join.sanitize
  rescue
    self.sanitize
  end
  
  def pretty_sms
    Iconv.iconv("ASCII//IGNORE//TRANSLIT", "UTF-8", self).join.sanitize_sms
  rescue
    self.sanitize_sms
  end
  
  def to_hashtribute
	hashtribute = {}
	self.split(";").each{ |couple|
			hashtribute[couple.split(":").first] = couple.split(":").second
		}
	return hashtribute
  end
  
  def sanitize
    self.gsub(/[^a-z._0-9 -]/i, "").tr(".", "_").gsub(/(\s+)/, "_").dasherize.downcase
  end
  
  def sanitize_sms
    self.gsub(/[^a-zA-Z\/\n()?!:._0-9 -]/i, "")
  end
  
end

class Numeric
  def humanize(rounding=2,delimiter='.',separator=',')
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
  
  def humanize
	return self.to_i.to_s
  end
end