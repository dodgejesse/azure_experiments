mkdir projects
mkdir software

sudo apt-get install unzip
yes | sudo apt-get install emacs
sudo apt-get install htop


# anaconda
cd software
wget https://repo.continuum.io/archive/Anaconda2-5.0.1-Linux-x86_64.sh
bash Anaconda2-5.0.1-Linux-x86_64.sh
# follow commands, put in /home/jessedd/software/anaconda2
rm Anaconda2-5.0.1-Linux-x86_64.sh

conda create --name hparamopt python numpy nltk

# if we want to get the .pub key on there:
scp -r -i jesse-key-pair-uswest2.pem jesse-key-pair-uswest2.pem jessedd@IP.ADDRESS.HERE:/home/jessedd/

Standard_F16s_v2


