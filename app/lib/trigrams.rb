def trigrams(str, stopchar='*')
  result = []
  to_scan = stopchar + str.downcase + stopchar
  (0..to_scan.length-3).each do |i|
    result << to_scan[i..i+2]
  end
  result
end
