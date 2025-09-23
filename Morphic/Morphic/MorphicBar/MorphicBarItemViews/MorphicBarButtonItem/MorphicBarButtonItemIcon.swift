// Copyright 2020 Raising the Floor - US, Inc.
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation

import Foundation

enum MorphicBarButtonItemIcon: String {
    case abcnews = "abcnews"
//    case aljazeera = "aljazeera"
    case amazon = "amazon"
//    case amazonMusic = "amazonmusic"
    case aol = "aolold"
    case appleMusic = "itunes"
    case bbc = "bbc"
    case bestBuy = "bestbuy"
    case bloomberg = "bloomberg"
    case box = "box"
    case calculator = "calculator"
    case calendar = "calendar$calendar"
    case cbsNews = "cbsnews"
    case chrome = "chrome"
    case cnbc = "cnbc"
    case cnn = "cnn"
    case comments = "comments"
    case craigslist = "craigslist"
    case deezer = "deezer"
    case disneyPlus = "disneyplus"
    case dropbox = "dropbox"
    case drudgereport = "drudgereport"
//    case ebay = "ebay"
    case etsy = "etsy"
    case envelope = "email$envelope"
    case envelopeOpen = "email$envelopeopen"
    case envelopeOpenText = "email$envelopeopentext"
    case envelopeOutline = "email$envelopeoutline"
    case envelopeOutlineOpen = "email$envelopeoutlineopen"
    case facebook = "facebook"
    case firefox = "firefox"
    case forbes = "forbes"
    case foxnews1 = "faviconfoxnews"
    case foxnews2 = "foxnews"
    case globe = "globe"
    case gmail = "gmail"
    case googleDrive = "googledrive"
    case googleNews = "googlenews"
    case huffPost = "huffpost"
    case hulu = "hulu"
    case icloud = "icloud"
    case iHeartRadio = "iheartradio"
    case imgur = "imgur"
    case instagram = "instagram"
    case kohls = "kohls"
    case latimes = "latimes"
    case linkedin = "linkedin"
    case macys = "macys"
//    case mail = "mail"
    case msedge = "msedge"
    case msexcel = "msexcel"
    case msonenote = "msonenote"
    case msoutlook = "msoutlook"
    case mspowerpoint = "mspowerpoint"
    case msteams = "msteams"
    case msword = "msword"
    case nbcNews = "nbcnews"
    case netflix = "netflix"
    case newspaper = "news$newspaper"
    case newYorkTimes = "newyorktimes"
    case nextdoor = "nextdoor"
    case npr = "npr"
    case onedrive = "onedrive"
    case opera = "opera"
    case outlook = "outlook"
//    case pandora = "pandora"
    case pinterest = "pinterest"
    case reddit = "reddit"
    case reuters = "reuters"
    case skype = "skype"
    case spotify = "spotify"
    case soundcloud = "soundcloud"
    case target = "target"
    case theGuardian = "theguardian"
//    case theHill = "thehill"
//    case tidal = "tidal"
    case tumblr = "tumblr"
    case twitter = "twitter"
    case usaToday = "usatoday"
    case vimeo = "vimeo"
    case walmart = "walmart"
    case washingtonPost = "washingtonpost"
//    case wayfair = "wayfair"
    case windowMaximize = "windowmaximize"
    case wallStreetJournal = "wsj"
    case yahoo = "yahoo"
    case yahooMail = "yahoomail"
    case youtube = "youtube"
    case youtubeMusic = "youtubemusic"
    
    // NOTE: to convert SVGs to PDFs, we use the following command line on macOS; the tool (Inkscape) is also available on Windows and Linux
    // /Applications/Inkscape.app/Contents/macOS/inkscape --export-text-to-path --export-type=pdf <filename>.svg
    
    var pathToImage: String {
        get {
            let fileName = self.translateImageUrlToFileName(self.rawValue)
            // NOTE: once we add JPG support, uncomment this section (and also the mail entry above and below)
            
/*          if let pngPath = Bundle.main.path(forResource: fileName, ofType: "png") {
                return pngPath
            } else if let jpgPath = Bundle.main.path(forResource: fileName, ofType: "jpg") {
                return jpgPath
             } else if let jpegPath = Bundle.main.path(forResource: fileName, ofType: "jpeg") {
                 return jpegPath
            } else */ if let pdfPath = Bundle.main.path(forResource: fileName, ofType: "pdf") {
                return pdfPath
            } else {
                fatalError("File path to built-in image is invalid")
            }
        }
    }
    
    // NOTE: the image_url values we get back from the v1 API do not always represent the filename, so we need to map them here
    //       in the (very-near-term) future, we must standardize on URLs or another form via the API; manual mapping is not sustainable
    func translateImageUrlToFileName(_ imageUrl: String) -> String {
        switch imageUrl {
        case "abcnews":
            return "logo_abcNews"
//        case "aljazeera":
//            return "logo_alJazeera"
//        case "amazonmusic":
//            return "logo_amazonMusic"
        case "amazon":
            return "logo_amazon"
        case "aolold":
            return "logo_aolOld"
        case "bbc":
            return "logo_bbc"
        case "bestbuy":
            return "logo_bestBuy"
        case "bloomberg":
            return "logo_bloomberg"
        case "box":
            return "logo_box"
        case "calculator":
            return "logo_calculator"
        case "calendar$calendar":
            return "calendar"
        case "cbsnews":
            return "logo_cbsNews"
        case "chrome":
            return "logo_chrome"
        case "cnbc":
            return "logo_cnbc"
        case "cnn":
            return "logo_cnn"
        case "craigslist":
            return "logo_craigslist"
        case "deezer":
            return "logo_deezer"
        case "disneyplus":
            return "logo_disneyPlus"
        case "dropbox":
            return "logo_dropbox"
        case "drudgereport":
            return "logo_drudgeReport"
//        case "ebay":
//            return "logo_ebay"
        case "email$envelope":
            return "envelope"
        case "email$envelopeopen":
            return "envelope_open"
        case "email$envelopeopentext":
            return "envelope_open_text"
        case "email$envelopeoutline":
            return "envelope_outline"
        case "email$envelopeoutlineopen":
            return "envelope_outline_open"
        case "etsy":
            return "logo_etsy"
        case "facebook":
            return "logo_facebook"
        case "faviconfoxnews":
            return "favicon_foxNews"
        case "firefox":
            return "logo_firefox"
        case "forbes":
            return "logo_forbes"
        case "foxnews":
            return "logo_foxNews"
        case "gmail":
            return "logo_gmail"
        case "googledrive":
            return "logo_googleDrive"
        case "googlenews":
            return "logo_googleNews"
        case "huffpost":
            return "logo_huffpost"
        case "hulu":
            return "logo_hulu"
        case "icloud":
            return "logo_icloud"
        case "iheartradio":
            return "logo_iheartRadio"
        case "imgur":
            return "logo_imgur"
        case "instagram":
            return "logo_instagram"
        case "itunes":
            return "logo_itunes"
        case "kohls":
            return "logo_kohls"
        case "latimes":
            return "logo_laTimes"
        case "linkedin":
            return "logo_linkedIn"
        case "macys":
            return "logo_macys"
//        case "mail":
//            return "logo_mail"
        case "msedge":
            return "logo_msedge"
        case "msexcel":
            return "logo_msexcel"
        case "msonenote":
            return "logo_msonenote"
        case "msoutlook":
            return "logo_msoutlook"
        case "mspowerpoint":
            return "logo_mspowerpoint"
        case "msteams":
            return "logo_msteams"
        case "msword":
            return "logo_msword"
        case "nbcnews":
            return "logo_nbcNews"
        case "netflix":
            return "logo_netflix"
        case "news$newspaper":
            return "newspaper"
        case "newyorktimes":
            return "logo_newYorkTimes"
        case "nextdoor":
            return "logo_nextdoor"
        case "npr":
            return "logo_npr"
        case "onedrive":
            return "logo_onedrive"
        case "opera":
            return "logo_opera"
        case "outlook":
            return "logo_outlook"
//        case "pandora":
//            return "logo_pandora"
        case "pinterest":
            return "logo_pinterest"
        case "reddit":
            return "logo_reddit"
        case "reuters":
            return "logo_reuters"
        case "skype":
            return "logo_skype"
        case "soundcloud":
            return "logo_soundcloud"
        case "spotify":
            return "logo_spotify"
        case "target":
            return "logo_target"
        case "theguardian":
            return "logo_theGuardian"
//        case "thehill":
//            return "logo_theHill"
        case "tidal":
            return "logo_tidal"
        case "twitter":
            return "logo_twitter"
        case "tumblr":
            return "logo_tumblr"
        case "usatoday":
            return "logo_usaToday"
        case "vimeo":
            return "logo_vimeo"
        case "walmart":
            return "logo_walmart"
        case "washingtonpost":
            return "logo_washingtonPost"
//        case "wayfair":
//            return "logo_wayfair"
        case "wsj":
            return "logo_wsj"
        case "windowmaximize":
            return "window_maximize"
        case "yahoo":
            return "logo_yahoo"
        case "yahoomail":
            return "logo_yahoomail"
        case "youtube":
            return "logo_youtube"
        case "youtubemusic":
            return "logo_youtubeMusic"
        default:
            return imageUrl
        }
    }
}
