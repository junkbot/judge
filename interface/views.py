from django.core.context_processors import csrf
from django.shortcuts import render_to_response
from django.views.decorators.csrf import csrf_protect
import commands, os

def submit(request):
	# csrf protection
	c = {}
	c.update(csrf(request))

	# render the html form
	return render_to_response('submit.html',c)

def judge(request):
	# read the form data into variables
	username = request.POST['username']
	print "username:",username
	problem = request.POST['problem']
	print "problem:",problem
	lang = request.POST['lang']
	print "lang:",lang
	source = request.POST['source']
	print "source:"
	print source

	# find the correct file extension
	if lang == "C":
		extn = ".c"	
	elif lang == "C++":
		extn = ".cpp"
	elif lang == "Pascal":
		extn = ".pas"

	baseFileName = problem + extn

	os.chdir("/home/joshua/sandbox/judge/")
	
	# make a file with the code inside
	codeFile = open(baseFileName,"w")
	codeFile.write(source+"\n")
	codeFile.close()

	judge_output = commands.getoutput("bash tester.sh "+baseFileName+" "+username)

	return render_to_response('score.html',locals())
