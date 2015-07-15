

function search(query) {
  $('#questionText').html(query);
  $("#response").html("<p class='response'>loading...</p>");

    $.ajax({url: "/ask?query="+query, success: function(result){
        
        var content = "";
        
        for (var x=0; x<result.answers.length; x++ ) {
            if (result.answers[x].text) {
                content += "<li style='padding-top:10px;'>"+result.answers[x].text+" Confidence: "+parseFloat(result.answers[x].value).toFixed(2);+"</li>";
            }   
        }
        
        $("#response").html("<ul>"+content+"</ul>");
    }});
}
