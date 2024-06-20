#!/usr/bin/bash

echo "Welcome to flask app automation"
echo "==================================="
echo "
Choose the database you want to go with"
echo "---------------"
echo "1 . Postgresql
2. Sqlite
3. Mongodb "
echo "=====enter your preferred database number below(1/2/3)=========="

read choice



########################################################################

mkdir app
touch run.py
touch requirements.txt

cd app

mkdir static;mkdir templates
touch __init__.py;touch config.py;touch model.py;touch dbsetup.py;touch forms.py;touch view.py


##################################################################################

configfile="config.py"

cat <<EOF > $configfile

import os

class config():
    SQLALCHEMY_DATABASE_URI=None
    SQLALCHEMY_TRACK_MODIFICATIONS=False
    SECRET_KEY='secertkey'

class sqliteconfig(config):
    basedir=os.path.abspath(os.path.dirname(__file__))
    SQLALCHEMY_DATABASE_URI='sqlite:///'+os.path.join(basedir,'testdata.sqlite3')

class postgresconfig(config):
    SQLALCHEMY_DATABASE_URI= 'postgresql://postgres:postgres@localhost:5432/testdata'

EOF

###########################################################################

form="forms.py"

cat <<EOF > $form

from flask_wtf import FlaskForm
from wtforms import StringField,SubmitField,PasswordField
from wtforms.validators import DataRequired,Email,EqualTo,Length

######################################################

class Usersregistration(FlaskForm):
    name=StringField('Enter your name: ',validators=[DataRequired()])
    email=StringField('Enter your email: ',validators=[DataRequired(),Email()],render_kw={'placeholder':'abc@xyzmail.com'})
    password=PasswordField('Password: ',validators=[DataRequired(),Length(min=8),EqualTo('pass_confirm',message='Passwords must match')],render_kw={'placeholder':'Min 8 charcters'})
    pass_confirm=PasswordField('Confirm password: ',validators=[DataRequired()])
    register=SubmitField('Register')

####################################################    

class Userslogin(FlaskForm):
    email=StringField('Enter your registered email: ',validators=[DataRequired(),Email()])
    password=PasswordField('Enter your password: ',validators=[DataRequired()])
    login=SubmitField('Log in')
    
EOF

#############################################################


dbset="dbsetup.py"

if [ $choice -eq 3 ]
then 
cat <<EOF > $dbset
from pymongo import MongoClient

client = MongoClient('mongodb://localhost:27017')
mongo = client['kavi']
collection = mongo['users']

EOF

else

cat <<EOF > $dbset
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
EOF

fi

##################################################################

vw="view.py"

cat <<EOF > $vw

from flask import render_template,redirect,url_for,current_app as app,jsonify
from app.forms import Usersregistration
from app.model import Users
from app.dbsetup import collection

########################################

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/sucessupdate')
def sucess():
    return render_template('sucess.html')


EOF

if [ $choice -eq 3 ]
then
cat <<EOF >> $vw
@app.route('/register',methods=['GET','POST'])
def register():
    form=Usersregistration()
    if form.validate_on_submit():
        user={"name":form.name.data,
              "email":form.email.data,
              "password":form.password.data}
        
        collection.insert_one(user)
        return redirect(url_for('sucess'))
    
    return render_template('register.html',form=form)
EOF
else
cat <<EOF >>$vw
@app.route('/register',methods=['GET','POST'])
def register():
    form=Usersregistration()
    if form.validate_on_submit():
        user=Users(name=form.name.data,
                  email=form.email.data,
                  password=form.password.data,
                  )
        
        with app.app_context():
            checkuser=Users.query.filter_by(email=form.email.data).first()
            if checkuser:
                return redirect(url_for('index'))
            else:
                db.session.add(user)
                db.session.commit()
                return redirect(url_for('sucess'))
    return render_template('register.html',form=form)

EOF
fi 


###########################################

model="model.py"

if [ $choice -eq 1 ] || [ $choice -eq 2 ]
then
cat <<EOF > $model
from app.dbsetup import db
from werkzeug.security import generate_password_hash,check_password_hash

class Users(db.Model):
    user_id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(255))
    email = db.Column(db.String(255), unique=True)
    hashed_password = db.Column(db.String(255))

    
    def __init__(self,name,email,password):
        self.name=name
        self.email=email
        self.hashed_password=generate_password_hash(password)

        
    def check_password(self,password):
        return check_password_hash(self.hashed_password,password)
    
    def get_id(self):
        return (self.user_id)
EOF

fi

##############################################

cd ..

entry="run.py"

if [ $choice -eq 3 ]
then
cat <<EOF > $entry

from flask import Flask
from app import config
from app.config import sqliteconfig, postgresconfig,config

######################################

app=None

def create_app():
    app=Flask(__name__,template_folder="./app/templates")
    app.config.from_object(config)
    app.app_context().push()

    return app
    
app=create_app()

from app.view import *


if __name__=="__main__":
    app.run(debug=True)

EOF
elif [ $choice -eq 2 ]
then
cat <<EOF > $entry


from flask import Flask
from app import config
from app.dbsetup import db
from app.config import sqliteconfig, postgresconfig,config

######################################

app=None

def create_app():
    app=Flask(__name__,template_folder="./app/templates")
    app.config.from_object(config)
    app.config.from_object(sqliteconfig)
    db.init_app(app)

    app.app_context().push()

    with app.app_context():
        db.create_all()

    return app
    
app=create_app()

from app.view import *


if __name__=="__main__":
    app.run(debug=True)

EOF
elif [ $choice -eq 1 ]
then
cat <<EOF > $entry

from flask import Flask
from app import config
from app.dbsetup import db
from app.config import sqliteconfig, postgresconfig,config

######################################

app=None

def create_app():
    app=Flask(__name__,template_folder="./app/templates")
    app.config.from_object(config)
    app.config.from_object(postgresconfig)
    db.init_app(app)

    app.app_context().push()

    with app.app_context():
        db.create_all()

    return app
    
app=create_app()

from app.view import *


if __name__=="__main__":
    app.run(debug=True)

EOF

else
cat /dev/null > $entry

fi




