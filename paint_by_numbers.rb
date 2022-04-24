require 'irb'

class HSL < Struct.new(:h,:s,:l)
    def h_rotate(r)
        self.h += r
    end
    def invert()
        self.h += 180
        self.l = 1 - self.l
    end
end

class RGB < Struct.new(:r,:g,:b); end
class Pixel < Struct.new(:char,:fg,:bg); end

def hsl_to_rgb(color)
    color.h = color.h % 360
    c = (1-(2*color.l - 1).abs)*color.s
    x = c*(1-((color.h/60.0)%2 - 1).abs)
    m = color.l - c/2.0
    rp,gp,bp = if color.h <= 60
        [c,x,0]
    elsif color.h <= 120
        [x,c,0]
    elsif color.h <= 180
        [0,c,x]
    elsif color.h <= 240
        [0,x,c]
    elsif color.h <= 300
        [x,0,c]
    else
        [c,0,x]
    end
    RGB.new( ((rp+m)*255).to_i, ((gp+m)*255).to_i, ((bp+m)*255).to_i )
end

def setbg_rgb(c)
    "\x1b[48:2:#{c.r}:#{c.g}:#{c.b}m"
end

def setfg_rgb(c)
    "\x1b[38:2:#{c.r}:#{c.g}:#{c.b}m"
end

def setfg_hsl(color)
    setfg_rgb(hsl_to_rgb(color))
end

def setbg_hsl(color)
    setbg_rgb(hsl_to_rgb(color))
end

def reset_colors()
    "\x1b[0m"
end

def distance(r1,c1,r2,c2)
    Math.sqrt( (r1-r2)**2 + (c1-c2)**2 ) 
end

bird = File.read("/home/sean/Downloads/ascii-atredibird.txt")

lines = bird.split("\n")

pixels = lines.map{|l| l.each_byte.map{|b| Pixel.new(b,HSL.new(0,1,1),HSL.new(0,1,0)) } }

max_row = pixels.length
max_col = pixels.max{|a,b| a.length <=> b.length}.length
center_row = max_row / 2
center_col = max_col / 2

max_dist = distance(0,0,center_row,center_col)

pixels.each_with_index do |line,row|
    line.each_with_index do |pixel,col|
        y = (max_row - row) - center_row
        x = col - center_col
        tan_theta = y.to_f / x.to_f
        theta = Math.atan2(y,x)
        degrees = (theta/Math::PI * 180+180).to_i
        hue = degrees
        dist = distance(row,col,center_row,center_col)
        normal_dist = dist / max_dist
        if pixel.char > 32 # above the space char
            pixel.fg.h = hue
            pixel.fg.l = 1 - normal_dist
        end
        pixel.bg.h = 240
        pixel.bg.s = 1
        la = (max_dist-dist-3-(y.abs/1.25))
        if la > 0
            l = ( la**2 / max_dist.to_f**2) / 3
        else
            l = 0
        end
        pixel.bg.l = l  
    end
end

pixels.each_with_index do |line,row|
    # next if row < 11 or row > 32
    line.each do |pixel|
        pixel.fg.h_rotate(25)
        pixel.fg.invert
        pixel.bg.invert
        print setbg_hsl(pixel.bg)
        print setfg_hsl(pixel.fg)
        print pixel.char.chr
    end
    print reset_colors()
    puts
end

