// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .
var queue = [];
$(document).ready(function() {
  var male_count = 0;
  var female_count = 0;
  var current_count = 0;
  var total_count = 0;
  var male_figure = 0;
  var female_figure = 0;
  var delay = 40;
  var index = 0;
  var publish_enabled = false;
  function increase() {
    if (queue.length <= index) {
      publish_enabled = true;
      $("#message").hide();
      $("#complete").show();
      $("#publish_button").removeClass("disabled");
    } else {
      var data = queue[index++];
      $("#name").text(data[0]);
      current_count++;
      $("#current_count").text(current_count);
      $("#total_count").text(total_count);
      if (data[1]) {
        male_count++;
        $("#male_count").text(male_count);
      } else {
        female_count++;
        $("#female_count").text(female_count);
      }
      var male_ratio = Math.round(male_count*100.0/total_count-0.0001);
      var female_ratio = Math.round(female_count*100.0/total_count-0.0001);
      $("#male_bar").text(male_ratio+"%").css("width",male_ratio+"%");
      $("#female_bar").text(female_ratio+"%").css("width",female_ratio+"%");
      var new_male_figure = Math.min(male_count, Math.floor(male_ratio/2));
      while (male_figure < new_male_figure) {
        male_figure++;
        $("#male_figure").append("<img src=\"/assets/male.png\">");
      }
      var new_female_figure = Math.min(female_count, Math.floor(female_ratio/2));
      while (female_figure < new_female_figure) {
        female_figure++;
        $("#female_figure").append("<img src=\"/assets/female.png\">");
      }
      setTimeout(increase, delay);
    }
  }
  $("#start_button").click(function() {
    $("#process").show();
    $("#start_button").hide();
    $("#publish_button").css('display', 'inline-block');
    total_count = queue.length;
    if (total_count > 300)
      delay = delay * 300 / total_count;
    increase();
  });
  $("#publish_button").click(function() {
    if (publish_enabled) {
      publish_enabled = false;
      $("#publish_button").addClass("disabled");
      $.get('/publish', function() {
        $("#alert").show();
      });
    }
  });
});
