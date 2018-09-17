#footer {
   position:fixed;
   left:0px;
   bottom:0px;
   height:60px;
   width:100%;
   background:#999;
}
            .agreement_text_standard
            {
                font-family:georgia;
                font-size:10.5pt;
                }

table { font-family:georgia;
     font-size: 10.5pt;
    }

          ol { 
    /*Styling */
    /*important bit*/
    counter-reset: item; 
     }
          li1 { 
    /*Styling*/
    list-style: disc outside;
    display: block;
    position: relative;
    }
          li1:before { 
    /*Important bit*/
    content: counters(item, "."); counter-increment: item; 
    /*Styling*/
    font-family:georgia;
     font-size: 10.5pt;
    font-weight: normal;
    position: relative;
    list-style: disc outside;
        margin-right: 100%;

        
    }