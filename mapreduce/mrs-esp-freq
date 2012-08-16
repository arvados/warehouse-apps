#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'getoptlong'

$opts = {}
GetoptLong.
  new([ '--output-dict', GetoptLong::NO_ARGUMENT ],
      [ '--esp-file', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--enable-build-chr-pos-lookup', GetoptLong::NO_ARGUMENT ] ).
  each do |k,v|
  $opts[k] = v
end

# From...
# File shellwords.rb, line 73
def shellescape(str)
  # An empty argument will be skipped, so return empty quotes.
  return "''" if str.empty?

  str = str.dup

  # Treat multibyte characters as is.  It is caller's responsibility
  # to encode the string in the right encoding for the shell
  # environment.
  str.gsub!(/([^A-Za-z0-9_\-.,:\/@\n])/, "\\\\\\1")

  # A LF cannot be escaped with a backslash because a backslash + LF
  # combo is regarded as line continuation and simply ignored.
  str.gsub!(/\n/, "'\n'")

  return str
end

$aa_3to1 = {
  'Ala' => 'A',
  'Arg' => 'R',
  'Asn' => 'N',
  'Asp' => 'D',
  'Cys' => 'C',
  'Gln' => 'Q',
  'Glu' => 'E',
  'Gly' => 'G',
  'His' => 'H',
  'Ile' => 'I',
  'Leu' => 'L',
  'Lys' => 'K',
  'Met' => 'M',
  'Phe' => 'F',
  'Pro' => 'P',
  'Ser' => 'S',
  'Thr' => 'T',
  'Trp' => 'W',
  'Tyr' => 'Y',
  'Val' => 'V',
  'Xaa' => 'X',
  'Stop' => 'X'
}

def read_esp(chromosome)
  if chromosome
    chromosome = chromosome.sub(/^chr/i, '')
    chromarg = "'*.chr#{chromosome}.*'"
  else
    chromarg = ""
  end

  $esp_freq = {}
  $esp_detail = {}
  allele_count_field = []

  build = nil
  if $opts['--esp-file']
    esp_in = File.open($opts['--esp-file'])
  else
    locator = ENV['KNOB_ESP_TARBALL']
    esp_in = IO.popen("whget #{shellescape(locator)} - | tar --to-stdout --wildcards -xzf - #{chromarg} 2>/dev/null", 'r')
  end
  esp_in.each_line do |line|
    field = line.split ' '
    if line.match /^\#/
      if (x = field[0].match /^\#base\((.*?)\)/)
        build = x[0]
        allele_count_field = []
        headrow = field
        headrow.each_index do |i|
          if (m = headrow[i].match(/^(.*)AlleleCount$/))
            allele_count_field << [i, m[1]]
          end
        end
      end
      next
    end

    if chromosome && field[0].split(':')[0] != chromosome
      break if $esp_freq.size > 0
      next
    end

    allele = field[6].split '/'
    allele_count = allele.map { |x| x.split('=')[1].to_i }
    allele_tot = 0
    allele_count.each { |x| allele_tot += x }
    allele_freq = allele_count.map { |x| 1.0 * x / allele_tot } rescue []

    variant_names = []
    if !field[14].match /^(coding-syn|intron|utr-|near-gene-|intergenic)/
      aa = field[15].split ','
      aa.map! { |x| x.capitalize }
      gene = field[12]
      aapos = field[16].split '/'
      aa_from = $aa_3to1[aa.last] || aa.last
      aa.pop
      aa.each do |aa_to|
        aa_to = $aa_3to1[aa_to] || aa_to
        variant_names.push "#{gene} #{aa_from}#{aapos[0]}#{aa_to}"
      end
    elsif field[1] != 'none'
      variant_names.push field[1]
    elsif build and $opts['--enable-build-chr-pos-lookup']
      variant_names.push(build + ':' + field[0])
    else
      next
    end

    if $opts['--output-dict']
      chr,pos = field[0].split ':'
      allele.zip(allele_freq, variant_names) do |a, af, variant_name|
        puts "#{variant_name} chr#{chr} #{pos} #{a} #{af}"
      end
    else
      variant_names.zip(allele_freq) do |variant_name, af|
        $esp_freq[variant_name] = af
        $esp_detail[variant_name] = allele_count_field.map { |i,name| name + ':' + field[i] }.join(' ')
      end
    end
  end
end

if $opts['--output-dict']
  read_esp nil
  exit
end

current_chromosome = nil
ARGF.each_line do |line|
  begin
    v = JSON.parse(line)
    if v['chromosome'] != current_chromosome
      current_chromosome = v['chromosome']
      read_esp current_chromosome
    end
    variant_name = "#{v['gene']} #{v['amino_acid_change']}"
    if $esp_freq[variant_name]
      v['esp_freq'] = $esp_freq[variant_name]
      v['esp_detail'] = $esp_detail[variant_name]
      line = JSON.generate(v)
    end
  ensure
    puts line
  end
end
