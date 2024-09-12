from flask import Flask,render_template,request

dapp=Flask(__name__)

@dapp.route('/',methods=["get","post"])
def P2Plending():
    return render_template('P2Plending.html')


if __name__=='__main__':
    dapp.run()