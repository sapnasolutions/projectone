class Guest < Hobo::Model::Guest

  def administrator?
    false
  end
  
  def admin?
    false
  end
  
  def client?
    false
  end

end
