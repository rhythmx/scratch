def hexdump(str)
  offset = 0
  str.scan(/.{1,16}/m).map {  |chunk|
    s1 = chunk[0,8]
    s2 = chunk[8,8] || ""
    h1 = s1.each_byte.map{ |b| "%02x"%b }.join(' ')
    h2 = s2.each_byte.map{ |b| "%02x"%b }.join(' ')
    a1 = s1.each_byte.map{ |b| (b >= 0x20 && b <= 0x7e ) ? b.chr : '.' }.join
    a2 = s2.each_byte.map{ |b| (b >= 0x20 && b <= 0x7e ) ? b.chr : '.' }.join
    offset += 16
    "0x%08x: %- 23s   %- 23s %- 8s   %- 8s\n"%[offset-16,h1,h2,a1,a2]
  }.join
end
