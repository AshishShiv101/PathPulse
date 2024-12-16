//import UIKit
//
//class NewsDataModel: Equatable {
//    var headline: String
//    var link: String
//    var image: UIImage?
//
//    init(headline: String, link: String, image: UIImage?) {
//        self.headline = headline
//        self.link = link
//        self.image = image
//    }
//
//    static func ==(lhs: NewsDataModel, rhs: NewsDataModel) -> Bool {
//        return lhs.headline == rhs.headline && lhs.link == rhs.link
//    }
//}
//let newsDataArray: [NewsDataModel] = [
//    NewsDataModel(
//        headline: "Tamil Nadu sees surge in extreme weather events in 2024: report",
//        link: "https://www.thehindu.com/news/national/tamil-nadu/tamil-nadu-sees-surge-in-extreme-weather-events-in-2024-report/article68848730.ece",
//        image: UIImage(named: "News1")
//    ),
//    NewsDataModel(
//        headline: "5 dead in Chennai IAF event: When does heat turn fatal, how should it be dealt with?",
//        link: "https://indianexpress.com/article/explained/everyday-explainers/iaf-event-chennai-heat-deaths-9608147/",
//        image: UIImage(named: "News9")
//    ),
//    NewsDataModel(
//        headline: "Chennai’s Marina Beach to host grand air show on Oct 6: Traffic advisory issued",
//        link: "https://timesofindia.indiatimes.com/travel/travel-news/chennais-marina-beach-to-host-grand-air-show-on-oct-6-traffic-advisory-issued/articleshow/113960880.cms",
//        image: UIImage(named: "News10")
//    ),
//    NewsDataModel(
//        headline: "Traffic woes worsen in Chennai amid torrential rains",
//        link: "https://www.livemint.com/news/india/tamil-nadu-weather-alert-traffic-chaos-in-chennai-heavy-rains-latest-news-11123456789112.html",
//        image: UIImage(named: "News4")
//    ),
//    NewsDataModel(
//        headline: "Chennai Weather Update: Planning To Head Out This Weekend? Check Forecast First",
//        link: "https://www.timesnownews.com/chennai/chennai-weather-update-planning-to-head-out-this-weekend-check-forecast-first-article-114565651",
//        image: UIImage(named: "News5")
//    ),
//    NewsDataModel(
//        headline: "Upcoming Cyclone In Bay Of Bengal To Intensify Chennai's Rainfall Challenges",
//        link: "https://www.nativeplanet.com/news/upcoming-cyclone-in-bay-of-bengal-to-intensify-chennais-rainfall-challenges-011-014071.html",
//        image: UIImage(named: "News2")
//    ),
//    NewsDataModel(
//        headline: "Chennai weather update: Rains to continue this week. Check IMD's forecast for next one week for Tamil Nadu",
//        link: "https://economictimes.indiatimes.com/news/india/chennai-weather-update-rains-to-continue-this-week-check-imds-forecast-for-next-one-week-for-tamil-nadu/articleshow/112275668.cms?from=mdr",
//        image: UIImage(named: "News5")
//    )
//]
//
//let last24HoursNews: [NewsDataModel] = [
//    NewsDataModel(
//        headline: "Chennai Rain News Highlights: Heavy Rain in Tamil Nadu for the Next 2 Days, Says IMD",
//        link: "https://www.timesnownews.com/chennai/chennai-rain-live-updates-imd-issues-orange-alert-in-tamil-nadu-colleges-school-news-today-weather-update-liveblog-114222848",
//        image: UIImage(named: "News8")
//    ),
//    NewsDataModel(
//        headline: "Chennai Weather Update Today, October 24, 2024: Current Temperature, AQI, IMD Forecast for Tomorrow and Next 7 Days",
//        link: "https://news24online.com/uncategorized/chennai-weather-update-today-october-24-2024-current-temperature-aqi-imd-forecast-for-tomorrow-and-next-7-days/365938/",
//        image: UIImage(named: "News7")
//    ),
//    NewsDataModel(
//        headline: "'Northeast Monsoon is very rigorous over Tamil Nadu': IMD warns of heavy to extremely heavy rainfall in next 24 hrs",
//        link: "https://www.businesstoday.in/india/story/northeast-monsoon-is-very-rigorous-over-tamil-nadu-imd-warns-of-heavy-to-extremely-heavy-rainfall-in-next-24-hrs-chennai-rain-450363-2024-10-16",
//        image: UIImage(named: "News6")
//    ),
//    NewsDataModel(
//        headline: "Chennai Rain: Lightning Strikes Chennai During Midnight Rain, See Viral Video",
//        link: "https://www.oneindia.com/chennai/chennai-rain-lightning-strikes-chennai-during-midnight-rain-see-viral-video-011-3960533.html",
//        image: UIImage(named: "News5")
//    ),
//    NewsDataModel(
//        headline: "Monsoon 2024 reports highest number of very-heavy and extremely-heavy rainfall events in last 5 years",
//        link: "https://economictimes.indiatimes.com/news/india/chennai-weather-update-rains-to-continue-this-week-check-imds-forecast-for-next-one-week-for-tamil-nadu/articleshow/112275668.cms?from=mdr",
//        image: UIImage(named: "News4")
//    ),
//    NewsDataModel(
//        headline: "Northeast Monsoon: Chennai receives highest rainfall this season",
//        link: "https://www.news18.com/india/chennai-receives-highest-rainfall-northeast-monsoon-update-latest-news-9117050.html",
//        image: UIImage(named: "News1")
//    ),
//    NewsDataModel(
//        headline: "Chennai Weather Update: Planning To Head Out This Weekend? Check Forecast First",
//        link: "https://www.timesnownews.com/chennai/chennai-weather-update-planning-to-head-out-this-weekend-check-forecast-first-article-114565651",
//        image: UIImage(named: "News3")
//    ),
//]
//
//
//let weatherNews: [NewsDataModel] =  [
//    NewsDataModel(
//        headline: "Tamil Nadu sees surge in extreme weather events in 2024: report",
//        link: "https://www.thehindu.com/news/national/tamil-nadu/tamil-nadu-sees-surge-in-extreme-weather-events-in-2024-report/article68848730.ece",
//        image: UIImage(named: "News1")
//    ),
//    NewsDataModel(
//        headline: "Traffic woes worsen in Chennai amid torrential rains",
//        link: "https://www.livemint.com/news/india/tamil-nadu-weather-alert-traffic-chaos-in-chennai-heavy-rains-latest-news-11123456789112.html",
//        image: UIImage(named: "News4")
//    ),
//    NewsDataModel(
//        headline: "Chennai Weather Update: Planning To Head Out This Weekend? Check Forecast First",
//        link: "https://www.timesnownews.com/chennai/chennai-weather-update-planning-to-head-out-this-weekend-check-forecast-first-article-114565651",
//        image: UIImage(named: "News5")
//    ),
//    NewsDataModel(
//        headline: "Normal Rains Expected in Chennai Region, No Extreme Weather Likely: Tamil Nadu Weatherman",
//        link: "https://www.livechennai.com/detailnews.asp?newsid=72454",
//        image: UIImage(named: "News2")
//    ),
//    NewsDataModel(
//        headline: "Chennai weather update: Rains to continue this week. Check IMD's forecast for next one week for Tamil Nadu",
//        link: "https://economictimes.indiatimes.com/news/india/chennai-weather-update-rains-to-continue-this-week-check-imds-forecast-for-next-one-week-for-tamil-nadu/articleshow/112275668.cms?from=mdr",
//        image: UIImage(named: "News3")
//    )
//]
