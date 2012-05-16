// ==UserScript==
//@name            4chan bbcode
//@version         0.8
//@author          Frebith
//@description     Adds bbcode to 4chan imageboards and enables passive non-breaking spaces when posting
//@license         MIT; http://www.opensource.org/licenses/mit-license.php
//@include         http:*//boards.4chan.org/*
//@run-at          document-start
//@updateURL       https://raw.github.com/Frebith/4chanbbcode/master/4chan-bbcode.js
// ==/UserScript==



/*
*Copyright (c) 2012 Frebith
*Permission is hereby granted, free of charge, to any person obtaining a copy of this software 
*and associated documentation files (the 'Software'), to deal in the Software without restriction, 
*including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense,
*and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do 
*so, subject to the following conditions: 
*
*The above copyright notice and this permission notice shall be included in all copies or substantial 
*portions of the Software. 
*
*THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT 
*LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN 
*NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
*WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
*SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
var oldPosts = new Array();
var UPDATETIME = 5000;
var css = document.createElement('style');
css.type = 'text/css';
css.innerHTML = '.spoiler{background:#000;color:#000;}\n.spoiler:hover{color:#FFF;}\n.aa{text-align:left;font-family:IPAMonaPGothic,Mona,\'MS PGothic\',YOzFontAA97 !important}\n.o{text-decoration:overline}\ntt{font-size:smaller}';
document.body.appendChild(css);
var updateS = setTimeout(updateSubmit, UPDATETIME);
updateSubmit();
function updateSubmit() {
    var inputs = document.getElementsByTagName('form');
    for (var i = 0; i < inputs.length; i += 1) {
        if (inputs[i].getAttribute('id') !== 'delform') {
            inputs[i].addEventListener('submit', function (e) {
                return spacify();
            }, false);
        };
    };
    return updateS = setTimeout(updateSubmit, UPDATETIME);
};
function spacify() {
    var textAreas = document.getElementsByTagName('textarea');
    for (var i = 0; i < textAreas.length; i += 1) {
        updateText(textAreas[i]);
    };
};
function updateText(text) {
    var newText = '';
    var ch = '';
    var spec = false;
    var spc = 0;
    var lc = '';
    for (var i = 0; i < text.value.length; i += 1) {
        lc = ch.charAt(ch.length - 1);
        ch = text.value.charAt(i);
        if (ch === ' ') {
            if (spec) {
                ++spc;
                ch = '(sp ';
            } else {
                ch = ' ';
            };
            spec = true;
        } else if (ch === '\n') {
            for (var j = 0; j < spc; j += 1) {
                ch = ')' + ch;
            };
            spec = false;
            spc = 0;
        } else {
            spec = false;
        };
        newText += ch;
    };
    for (var i = 0; i < spc; i += 1) {
        newText += ')';
    };
    text.value = newText;
    return true;
};
var update = setTimeout(checkThread, UPDATETIME);
checkThread();
function checkThread() {
    var posts = document.getElementsByClassName('postMessage');
    for (var i = 0; i < posts.length; i += 1) {
        if (oldPosts.indexOf(posts[i].getAttribute('id')) === -1) {
            updatePosts(posts[i]);
            oldPosts.push(posts[i].getAttribute('id'));
        };
    };
    update = setTimeout(checkThread, UPDATETIME);
    return true;
};
function updatePosts(post) {
    var newPost = '';
    var mTag = '';
    var cTag = '';
    var tags = new Array();
    var matching = false;
    var ch = '';
    for (var i = 0; i < post.innerHTML.length; i += 1) {
        ch = post.innerHTML.charAt(i);
        if (matching) {
            if (ch === ' ' || ch === '<') {
                matching = false;
                tags.push(cTag);
                cTag = mTag;
                mTag = '';
                switch (cTag) {
                case 'b':
                    newPost += '<b>';
                    break;
                case 'u':
                    newPost += '<u>';
                    break;
                case 'i':
                    newPost += '<i>';
                    break;
                case 's':
                    newPost += '<s>';
                    break;
                case 'o':
                    newPost += '<span class="o">';
                    break;
                case 'm':
                    newPost += '<tt>';
                    break;
                case 'spoiler':
                    newPost += '<span class="spoiler" onmouseout="this.style.color=this.style.backgroundColor=\'#000\'" onmouseover="this.style.color=\'#FFF\';">';
                    break;
                case 'sup':
                    newPost += '<sup>';
                    break;
                case 'sub':
                    newPost += '<sub>';
                    break;
                case 'aa':
                    newPost += '<span class="aa">';
                    break;
                case 'sp':
                    if (newPost.charAt(newPost.length - 1) === ' ') {
                        newPost = newPost.substring(0, newPost.length - 1) + '&nbsp;';
                    } else {
                        newPost += '&nbsp;';
                    };
                    break;
                default:
                    newPost = newPost + '(' + cTag + ' ';
                    cTag = '';
                };
                if (ch === '<') {
                    newPost += '<';
                };
            } else if (ch === ')') {
                matching = false;
                newPost = newPost + '(' + mTag + ')';
                mTag = '';
            } else {
                mTag += ch;
            };
        } else {
            if (ch === '(') {
                matching = true;
            } else if (ch === ')' && cTag) {
                newPost += finishTag(cTag);
                cTag = tags.pop();
            } else {
                newPost += ch;
            };
        };
    };
    post.innerHTML = newPost;
    return true;
};
function finishTag(tag) {
    switch (tag) {
    case 'b':
        return '</b>';
    case 'u':
        return '</u>';
    case 'i':
        return '</i>';
    case 's':
        return '</s>';
    case 'm':
        return '</tt>';
    case 'sup':
        return '</sup>';
    case 'sub':
        return '</sub>';
    case 'spoiler':
    case 'o':
    case 'aa':
        return '</span>';
    default:
        return '';
    };
};
