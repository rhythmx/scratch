import wave, math, struct, os
from gtts import gTTS

class EASMessage:
    def __init__(self):
        self.sample_rate = 48000

        self.obj = wave.open("infosecemergency.wav","wb")
        self.obj.setnchannels(1)
        self.obj.setsampwidth(2)
        self.obj.setframerate(self.sample_rate)

    def gen_tone(self, frequency, seconds):
        for i in range(int(self.sample_rate * seconds)):
            samp = 32767*math.sin(2*math.pi * i * frequency / self.sample_rate);
            #print "samp is %i - %i" % (int(samp),i)
            self.obj.writeframesraw(struct.pack('<h',int(samp)))

    def gen_multitone(self, freq1, freq2, seconds):
        for i in range(int(self.sample_rate * seconds)):
            samp1 = 32767*math.sin(2*math.pi * i * freq1 / self.sample_rate) / 2;
            samp2 = 32767*math.sin(2*math.pi * i * freq2 / self.sample_rate) / 2;
            self.obj.writeframesraw(struct.pack('<h',int(samp1+samp2)))

    def gen_silence(self,seconds):
        val = struct.pack('<h',0);
        for i in range(int(self.sample_rate * seconds)):
            self.obj.writeframesraw(val)

    def encode_byte(self,ascii_code):
        for i in range(8):
            if ascii_code & (1 << i) != 0:
                self.gen_tone(2083.3333, 0.00192)
            else:
                self.gen_tone(1562.5, 0.00192)

    def encode_preamble(self):
        for i in range(16):
            self.encode_byte(0xAB)

    def encode_string(self,str):
        for b in bytes(str, encoding='ascii'):
            self.encode_byte(b)

    def gen_voice(self, message):
        myobj = gTTS(text = message, lang='en', slow=False)
        myobj.save("/tmp/lol.wav")
        os.system("ffmpeg -y -i /tmp/lol.wav -ar 48000 -ac 1 -f wav -acodec pcm_s16le /tmp/lol2.wav")
        voice = wave.open("/tmp/lol2.wav","rb")
        running = True
        while running:
            frames = voice.readframes(1024)
            if len(frames) > 0:
                self.obj.writeframesraw(frames)
            else:
                running = False

    def generate(self,eas_str,voice_msg):

        self.gen_silence(1)
        self.encode_preamble()
        self.encode_string(eas_str)
        self.gen_silence(1)
        self.encode_preamble()
        self.encode_string(eas_str)
        self.gen_silence(1)
        self.encode_preamble()
        self.encode_string(eas_str)
        self.gen_silence(1)
        self.gen_multitone(853,960,8.5)
        self.gen_silence(1)

        self.gen_voice(voice_msg)

        self.gen_silence(1)
        self.encode_preamble()
        self.encode_string("NNNN")
        self.gen_silence(1)
        self.encode_preamble()
        self.encode_string("NNNN")
        self.gen_silence(1)
        self.encode_preamble()
        self.encode_string("NNNN")

eas = EASMessage()
# https://en.wikipedia.org/wiki/Specific_Area_Message_Encoding
# Presidential Alert for all of TX on May 19th at 10PM for 24hrs issued by your mom
eas.generate("ZCZC-PEP-FRW-0TX000+2400-1402200-YOURMOM-","This is a fake presidential alert. An internet security dumpster fire has been detected in your area. This is a fake presidential alert")

