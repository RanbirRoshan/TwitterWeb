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
    payload.data = payload.data.sort((a, b) => (a.count < b.count) ? 1 : -1)
    $.each( payload.data, function(key, data) {
        var html_txt = "<div>" + data.Tag + "   " + data.count + "</div>"
        $("#TagCount").append(html_txt);
    });
});

channel.on("userCount", function (payload) {
    $("#UserCount").html("");
    payload.data = payload.data.sort((a, b) => (a.count < b.count) ? 1 : -1)
    $.each( payload.data, function(key, data) {
        var html_txt = "<div>" + data.username + "   " + data.count + "</div>"
        $("#UserCount").append(html_txt);
    });
});

channel.join();