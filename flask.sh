#!/usr/bin/bash

mkdir app
touch run.py
touch requirements.txt

cd app

mkdir static;mkdir templates
touch __init__.py;touch config.py;touch model.py;touch dbsetup.py;touch forms.py;touch view.py



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


dbset="dbsetup.py"

cat <<EOF > $dbset

from pymongo import MongoClient


client = MongoClient('mongodb://localhost:27017')
mongo = client['kavi']
collection = mongo['users']

EOF

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

vw="view.py"

cat <<EOF > $vw

from flask import render_template,redirect,url_for,current_app as app,jsonify
from app.forms import Usersregistration
# from app.model import Users
from app.dbsetup import collection

########################################

@app.route('/')
def index():
    return render_template('index.html')

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

@app.route('/sucessupdate')
def sucess():
    return render_template('sucess.html')
        
EOF

cd ..

entry="run.py"

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



