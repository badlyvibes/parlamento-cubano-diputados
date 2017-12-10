require 'unicode_utils'
require 'scraperwiki'
require 'mechanize'

def paragraph(p)
  element = @page.at(
    "//*/div[#{@div_y}]/div[#{@div_x}]/div/div/div[2]/div/p[#{p}]"
  )
  !element.nil? ? element.text.strip : ''
end

def name
  UnicodeUtils.titlecase(paragraph(1), :es)
end

def municipality
  m = paragraph(2)
  # Remove: Electo/Electa/Elegido por el / Municipio: / Nivel[...]
  m = m.gsub(/[Mm]unicipio:/, '')
  m = m.gsub(/[Ee]le.+?por el/, '')
  m = m.gsub(/Nivel.+?\./, '')
  m = m.delete('.')
  m.strip
end

def occupation
  paragraph(3).gsub('Ocupación: ', '').gsub(/\.$/, '')
end

def image
  @page.at(
    "//*/div[#{@div_y}]/div[#{@div_x}]/div/div/div[1]/figure/*/img"
  ).attribute('src').value
end

def scrape
  while name != ''
    m = municipality
    o = occupation
    # Sometimes occupation details are in the municipality paragraph
    o = m['Ocupación:'] ? m.gsub(/.+?Ocupación:/, '').gsub(/\.$/, '') : o
    m.gsub(/Ocupación.+?$/, '')

    puts ScraperWiki.save_sqlite([:name], name: name, municipality: m, occupation: o, image: image)

    @div_x = @div_x + 1
    @div_x = name == '' ? 1 : @div_x
    @div_y = @div_x == 1 ? @div_y + 1 : @div_y
  end
end

agent = Mechanize.new

# There are 16 regions
(1..16).each do |i|
  start_page = agent.get('http://www.parlamentocubano.cu/index.php/diputados/')
  anchor = "//*/div[1]/div/div/div/div[6]/div/ul/li[#{i}]/a"
  # Region page
  @page = agent.get(start_page.at(anchor).attribute('href').value)
  @div_x = 1
  @div_y = 1
  scrape
  i != 16 ? sleep(5) : nil # The server's in Cuba so can't take much load
end
