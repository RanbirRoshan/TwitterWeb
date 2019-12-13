// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"

let channel = socket.channel("twitter:tagCount", {});

channel.on("shout", function (payload) {
    $("#TagCount").html("");
    $("#TagSelect").html("<option value=\"\">Please Select</option>");
    $.each( payload.data, function(key, data) {
        var html_txt = "<option value=\""+data.Tag+"\">"+data.Tag+"</option>"
        $("#TagSelect").append(html_txt);
    });
    payload.data = payload.data.sort((a, b) => (a.count < b.count) ? 1 : -1)
    $("#TagCount").append("<table>");
    $.each( payload.data, function(key, data) {
        var html_txt = "<tr><td><div>" + data.Tag + "</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td>"+ data.count +"</td> </div></td></tr>"
        $("#TagCount").append(html_txt);
    });
    $("#TagCount").append("</table>");
});

channel.on("userCount", function (payload) {
    $("#UserCount").html("");
    $("#UserSelect").html("<option value=\"\">Please Select</option>");
    $("#UserSelect2").html("<option value=\"\">Please Select</option>");
    $.each( payload.data, function(key, data) {
        var html_txt = "<option value=\""+data.username+"\">"+data.username+"</option>"
        $("#UserSelect").append(html_txt);
        $("#UserSelect2").append(html_txt);
    });
    payload.data = payload.data.sort((a, b) => (a.count < b.count) ? 1 : -1)
    $("#UserCount").append("<table>");
    $.each( payload.data, function(key, data) {
        var html_txt = "<tr><td>" + data.username + "</td><td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td>" + data.count + "</td></tr>"
        $("#UserCount").append(html_txt);
    });
    $("#UserCount").append("</table>");
});

channel.on("tweetCout", function (payload) {
    $("#TweetCount").html("<div>" + payload.count + "</div>");
    $("#ReTweetCount").html("<div>" + payload.retweetcount + "</div>");
    $("#RecentTweets").html("");
    $.each(payload.list, function(key, data) {
        var html_txt = "<div>" + data + "</div>"
        $("#RecentTweets").append(html_txt);
    });
});

channel.on("getTagInfoData", function (payload) {
    var count = 0
    $("#TagFeed").html("");
    $.each(payload.val, function(key, data) {
        count = count + 1
        var html_txt = "<div>" + data + "</div><br>"
        $("#TagFeed").append(html_txt);
        if (count == 100){
            return false;
        }
        return true
    });
    $("#tagLable").html("Showing most recent" + count + " out of " + payload.val.length + "tweets");
});

channel.on("getUserFeedData", function (payload) {
    var count = 0
    $("#UserFeed").html("");
    $.each(payload.val, function(key, data) {
        count = count + 1
        var html_txt = "<div>" + data + "</div><br>"
        $("#UserFeed").append(html_txt);
        if (count == 100){
            return false;
        }
        return true
    });
    $("#userFeedLable").html("Showing most recent" + count + " out of " + payload.val.length + "tweets");
});

channel.on("getUserMentionsData", function (payload) {
    var count = 0
    $("#UserFeed2").html("");
    $.each(payload.val, function(key, data) {
        count = count + 1
        var html_txt = "<div>" + data + "</div><br>"
        $("#UserFeed2").append(html_txt);
        if (count == 100){
            return false;
        }
        return true
    });
    $("#userFeedLable2").html("Showing most recent" + count + " out of " + payload.val.length + "tweets");
});

channel.join();

$( "#TagSelect" ).change(function(d) {
    var str=""
    $( "#TagSelect option:selected" ).each(function() {
        str += $( this ).text() + " ";
        channel.push('getTagInfo', { // send the message to the server on "shout" channel
            tag: str
        });
    });
    console.log(str)
});


$( "#UserSelect" ).change(function(d) {
    var str=""
    $( "#UserSelect option:selected" ).each(function() {
        str += $( this ).text();
        channel.push('getUserFeed', { // send the message to the server on "shout" channel
            username: str
        });
    });
});


$( "#UserSelect2" ).change(function(d) {
    var str=""
    $( "#UserSelect2 option:selected" ).each(function() {
        str += $( this ).text();
        channel.push('getUserMentions', { // send the message to the server on "shout" channel
            username: str
        });
    });
});