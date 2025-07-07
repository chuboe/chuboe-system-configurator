```bash
## installation

# alternative: https://github.com/ideasman42/nerd-dictation/blob/main/package/python/readme.rst

mkdir -p ~/code/
cd ~/code/

sudo apt install -y python3-full python3-venv xdotool
git clone https://github.com/ideasman42/nerd-dictation.git
cd nerd-dictation
wget https://alphacephei.com/kaldi/models/vosk-model-small-en-us-0.15.zip

# small model
#wget https://alphacephei.com/vosk/models/vosk-model-en-us-0.22.zip
#unzip vosk-model-small-en-us-0.15.zip
#mv vosk-model-small-en-us-0.15 model

# large model 
wget https://alphacephei.com/vosk/models/vosk-model-en-us-0.22.zip
unzip vosk-model-en-us-0.22.zip
mv vosk-model-en-us-0.22 model

mkdir -p ~/.config/nerd-dictation
mv ./model ~/.config/nerd-dictation

python3 -m venv venv
source venv/bin/activate
pip install vosk

# Now try running nerd-dictation
#./nerd-dictation begin --vosk-model-dir=./model
```

```bash
## run

export DISPLAY=:1
source venv/bin/activate
./nerd-dictation begin
```
