jQuery.noConflict();  


/*
    javascript in this file controls the html page demonstrating the autosubject functionality

*/



/**************************************************************************************/
/*              Set up and initialization */
/**************************************************************************************/
/*
initial setup - called from onLoad
  attaches the autocomplete function to the search box
*/


var currentSuggestIndexDefault = "suggestall";  //initial default value

function setUpPage() {
// connect the autoSubject to the input areas
    jQuery('.fastbox').each( function(index, box) {
        //if id change suggestedIndex
        jQuery(box).autocomplete(	  {
          source: autoSubjectExample, 
          minLength: 1
      }).data( "autocomplete" )._renderItem = function( ul, item ) { formatSuggest(ul, item);};
    })

}  //end setUpPage()

/*  
    example style - simple reformatting
*/
function autoSubjectExample(request, response) {
  //loop HERE change index and do auto subject, append to array?
  id = this.element[0].className;
  if (id.includes('creator'))
    indexArray = ['suggest00', 'suggest10', 'suggest11'];
  else if (id.includes('contributor'))
    indexArray = ['suggest00', 'suggest10', 'suggest11'];
  else if (id.includes('subject'))
    indexArray = ['suggest00', 'suggest10', 'suggest11', 'suggest30', 'suggest50'];
  else if (id.includes('geographic_coverage'))
    indexArray = ['suggest51'];
  else
    indexArray = ['suggestall'];
  subjects = []
  jQuery.each(indexArray, function(index, value) {
    currentSuggestIndex = value;
    subjects.push(autoSubject(request, response, exampleStyle));
  });
}

/*
  For this example, replace the common subfield break of -- with  /
  */
  
function exampleStyle(res) {
  return res["auth"].replace("--","/"); 
   
}
