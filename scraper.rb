require 'unicode_utils'
require 'scraperwiki'
require 'mechanize'

def regional_page(i)
  anchor = "//*/div[1]/div/div/div/div[6]/div/ul/li[#{i}]/a"
  @agent.get(@index_page.at(anchor).attribute('href').value)
end

def scrape
  while name != ''
    m = municipality
    o = occupation
    # Sometimes occupation details are in the municipality paragraph
    o = m['Ocupación:'] ? m.gsub(/.+?Ocupación:/, '').gsub(/\.$/, '') : o
    m = m.gsub(/Ocupación.+?$/, '')

    puts ScraperWiki.save_sqlite([:name], name: name, municipality: m, occupation: o, image: image)

    @div_x = @div_x + 1
    @div_x = name == '' ? 1 : @div_x
    @div_y = @div_x == 1 ? @div_y + 1 : @div_y
  end
end

def paragraph(p)
  el = @page.at("//*/div[#{@div_y}]/div[#{@div_x}]/div/div/div[2]/div/p[#{p}]")
  !el.nil? ? el.text.strip : ''
end

def name
  UnicodeUtils.titlecase(paragraph(1), :es)
end

def municipality
  m = paragraph(2)
  # Remove: Electo/Electa/Elegido por el / Municipio: / Nivel[...]
  m = m.gsub(/[Mm]unicipio:/, '')
  m = m.gsub(/[Ee]le.+?por el/, '')
  m = m.gsub(/Nivel [Ee]scolar.+?\./, '')
  m = m.delete('.')
  m.strip
end

def occupation
  paragraph(3).gsub('Ocupación: ', '').gsub(/\.$/, '')
end

def image
  im = @page.at("//*/div[#{@div_y}]/div[#{@div_x}]/div/div/div[1]/figure/*/img")
  im.attribute('src').value
end

@agent = Mechanize.new
@index_page = @agent.get('http://www.parlamentocubano.cu/index.php/diputados/')

# There are 16 regional pages
(1..16).each do |i|
  @page = regional_page(i)
  @div_x = 1
  @div_y = 1
  scrape
end