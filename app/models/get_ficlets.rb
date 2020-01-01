class GetFiclets
  include HTTParty

  base_uri "http://localhost:3000"

  def get(path)
    self.class.get(path)
  end

end
