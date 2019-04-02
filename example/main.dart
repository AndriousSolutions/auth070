// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart'
    show
        AppBar,
        BoxConstraints,
        BuildContext,
        Center,
        CircularProgressIndicator,
        Column,
        ConstrainedBox,
        FutureBuilder,
        ListTile,
        MainAxisAlignment,
        MaterialApp,
        RaisedButton,
        Scaffold,
        State,
        StatefulWidget,
        Text,
        Widget,
        runApp;
import 'package:google_sign_in/google_sign_in.dart' show GoogleUserCircleAvatar;
import 'password.dart' show hiddenEmail, hiddenPassword;

import 'package:flutter_auth_buttons/flutter_auth_buttons.dart'
    show
        FacebookSignInButton,
        GoogleSignInButton,
        TwitterSignInButton,
        GithubSignInButton,
        InstagramSignInButton;

import 'package:auth070/auth.dart' show Auth;

void main() {
  runApp(
    MaterialApp(
      title: 'Google Sign In',
      home: SignInDemo(),
    ),
  );
}

class SignInDemo extends StatefulWidget {
  @override
  State createState() => SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {
  @override
  void initState() {
    super.initState();

    Auth.init(
      listen: (account) {
        setState(() {});
      },
    );
    Auth.signInAnonymously();
  }

  @override
  void dispose() {
    Auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Authentication Sign In'),
        ),
        body: FutureBuilder<bool>(
          future: Auth.hasLoggedIn(),
          builder: (_, snapshot) {
//            return snapshot.connectionState == ConnectionState.done
            return snapshot.hasData
                ? ConstrainedBox(
                    constraints: const BoxConstraints.expand(),
                    child: _buildBody(),
                  )
                : Center(child: CircularProgressIndicator());
          },
        ));
  }

  Widget _buildBody() {
    if (Auth.isLoggedIn()) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: Auth.identity,
            ),
            title: Text(Auth.displayName),
            subtitle: Text(Auth.email),
          ),
          const Text("Signed in successfully."),
          RaisedButton(
            child: const Text('SIGN OUT'),
            onPressed: () async {
              await Auth.signOut();
              setState(() {});
            },
          ),
          RaisedButton(
            child: const Text('SIGN OUT & DISCONNECT'),
            onPressed: () async {
              await Auth.disconnect();
              setState(() {});
            },
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          const Text("You are not currently signed in."),
          GoogleSignInButton(onPressed: () async {
            await Auth.signIn();
            setState(() {});
          }),
          RaisedButton(
            child: const Text('SIGN IN WITH EMAIL & PASSWORD'),
            onPressed: () async {
              await Auth.signInWithEmailAndPassword(
                  email: hiddenEmail, password: hiddenPassword);
              setState(() {});
            },
          ),
          RaisedButton(
            child: const Text('SIGN IN ANONYMOUSLY'),
            onPressed: () async {
              await Auth.signInAnonymously();
              setState(() {});
            },
          ),
          TwitterSignInButton(
            onPressed: () async {
              await Auth.signInWithTwitter();
              setState(() {});
            },
          ),
          GithubSignInButton(onPressed: () async {
            await Auth.signInWithGithub();
            setState(() {});
          }),
          FacebookSignInButton(
            onPressed: () async {
              await Auth.signInWithFacebook();
              setState(() {});
            },
          ),
          InstagramSignInButton(
            onPressed: () async {
              await Auth.signInWithInstagram();
              setState(() {});
            },
          ),
        ],
      );
    }
  }
}
