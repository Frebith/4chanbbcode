4chan bbcode
===========

It's written in Parenscript (see: bbcode.lisp)

You can compile the js file from bbcode.lisp by loading up your CL compiler of choice (i only tested on SBCL)
and running via:

- (require 'parenscript)
- (load "path/to/bbcode.lisp")
- (4BBC:compile-4bbc "filename.js")

if you don't have parenscript then quicklisp is your best choice for downloading common lisp packages.


# Supported bbcode are as followed:

- (b ...) => bold text
- (u ...) => underline
- (o ...) => overline
- (i ...) => italic
- (s ...) => strikethrough
- (m ...) => courier text
- (spoiler ...) => spoiler
- (sup ...) => smaller text that's raised on the line
- (sub ...) => smaller text that's lowered on the line
- (aa ...) => use for SJIS art
- (sp ) => space [These are done for the user unless you're using a QR (see: 4chan-x)]

# example usage

(b (i (u (o (s (m courier text) (spoiler n(sup o) (sub p)e) (aa jp-text))))))

(m
      \(^_^)/(sup V (sup I (sup P (sup P (sup E (sup R)))))))




Note: 4chan-x doesn't seem to play to well with this (backlinking and QR)

4chan's default post-form works good with it and 4chan's new QR addon works good with it (however, wait a few seconds before submitting from the QR so the script can attach to the submit for (sp ))



