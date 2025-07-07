```bash
## installation

# alternative: https://github.com/ideasman42/nerd-dictation/blob/main/package/python/readme.rst

mkdir -p ~/code/
cd ~/code/

sudo apt install -y python3-full python3-venv xdotool
git clone https://github.com/ideasman42/nerd-dictation.git
cd nerd-dictation

#model=vosk-model-small-en-us-0.15
#model=vosk-model-en-us-0.22
model=vosk-model-en-us-0.42-gigaspeech

wget https://alphacephei.com/vosk/models/$model.zip
unzip $model.zip
mv $model model

mkdir -p ~/.config/nerd-dictation
mv ./model ~/.config/nerd-dictation

python3 -m venv venv
source venv/bin/activate
pip install vosk
```

```bash
## run

export DISPLAY=:1
source venv/bin/activate
./nerd-dictation begin
```

