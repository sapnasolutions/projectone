etape a suivre :
- git install : next next next
- cr�er dossier c:\web applications\
- (au cas ou cr�er un compte github)
- ensuite sur github rattacher l'ordinateur (pour push and update) :
	http://help.github.com/win-set-up-git/
	- Git bash :
		- V�rifier qu'il existe un dossier .ssh dans le compte User windows
		- ssh-keygen -t rsa -C "email mis dans github"
		- mettre un mot de passe
		- ouvrir le fichier .\.ssh\id_rsa.pub
		- copier dans github : account setting : ssh public key : add an other key : copier le ssh : add key
- git bash :
	- go to c:\web applications\
	- git clone git@github.com:charleric/projectone.git
	- mettre yes
	- mettre mot de passe
	- chouette �a clone
- Install ruby : ATTENTION penser a mettre ruby dans le PATH
- Install rails :
	- ouvrir commande prompt ruby
	- se placer dans c:\web applications\nom du projet
	- extract le devkit dans le dossier de ruby (normalement c:\ruby1.9)
	- se placer dans le dossier devkit :
		- ruby dk.rb init
		- ruby dk.rb install
	- gem install rails (normalement il install plein de bordel)
	- gem install bundle
	- bundle install
	- bundle update rake (pour r�gl� le bug du rake : v�rifier que rake soit bien a la version 0.8.7)
- copie des dll mysql et sqlite3 dans system32 ou system64
- rake db:create ( au cas ajouter : RAILS_ENV="development" ) au cas ne pas tenir compte de l'erreur sur la cr�ation de la base mysql de test
- rake db:migrate ( au cas ajouter : RAILS_ENV="development" )
- R�cup�rer hobo-jquery :
	- se placer dans projet\vendor\plugins\
	- git clone git://github.com/bryanlarsen/hobo-jquery.git --branch rails3 
- rails s
- goto localhost:3000/x

Git :
- v�rifier toutes les derni�res mises � jour :
	- git fetch -v --all
- se brancher sur une branch distante
	- git branch -t nom_de_la_branche_locale origin/nom_de_la_branche_distante
- pusher sa branche (et cr�er la branche distante si elle n'existe pas) :
	- git push nom_de_la_branche_locale:nom_de_la_branche_distante
	- ducoup la branche local track sur la branche distante
- detruire une branche : git branch -d nom_de_la_branche
- detruire une branche distante : git push origin :nom_de_la_branche_distante
- rebase sa branche sur un master qui a avancer :
	- option branch/rebase a partir de la branche que l'on veut rebase
	- HEAD commits to selected commits
	- Selection du master et rebase
	ou alors en ligne de commande git
	- se mettre sur la branche que l'on veux rebase
	- git rebase master (ou nom de la branche sur laquelle on veux se rebase)
- git stash pour faire des sauvergarde temporaire pour au cas o�

Notepadd ++ : Bon choix pour le dev : petit ajout personnel de module :
- file switcher (penser a configurer le raccourci clavier)
- explorer

Rails console :
- pour test : ajout d'un client avec comme passerelle : logiciel = aptalis & params = code_agence:HOQUET774
- lancer un import globale : Importers.run Time.now
- lancer un import sur une passerelle : Importers.import objet_passerelle
- lancer un import sur un client : Importers.import objet_client