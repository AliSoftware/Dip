//: [Previous: Auto-injection](@previous)

import Dip

let container = DependencyContainer()

/*:
Let's say you are developing a killer e-mail client. Surely you want your users to feel comfortable using your service so you want to let them to use their existing accounts on other e-mail services like Gmail, Yahoo, Outlook. For that you will need some kind of screen where you will display the list of all 3'rd party services that you support. And of course you want to be able to easily add new services. Also you wish to split the work on different services between your teammates so that you ship this feature faster.

To enable all that you will need to define some common protocol that all 3'rd party services implementations will conform to.
Then you start to add concrete implementations:
*/

protocol ThirdPartyEmailService { /* … */ }

class GmailService: ThirdPartyEmailService { /* … */ init(){} }
class YahooService: ThirdPartyEmailService { /* … */ init(){} }
class OutlookService: ThirdPartyEmailService { /* … */ init(){} }

/*:
When ready you register them in the container.
*/

container.register(tag: "gmail") { GmailService() as ThirdPartyEmailService }
container.register(tag: "yahoo") { YahooService() as ThirdPartyEmailService }
container.register(tag: "outlook") { OutlookService() as ThirdPartyEmailService }

/*:
Then when you need to display all of them you can get them from the container just with one call.
*/

var thirdPartyServices = try! container.resolveAll() as [ThirdPartyEmailService]

/*:
When you realize that you need to support one more service you will only need to drop in it's implementation and register it in the container. It will appear in the list of your services without any other changes in your code.
*/

class YandexService: ThirdPartyEmailService { /* … */ init(){} }

container.register(tag: "yandex") { YandexService() as ThirdPartyEmailService }

thirdPartyServices = try! container.resolveAll() as [ThirdPartyEmailService]

/*:
Sharing to different services, providing different payment or goods delivery services, logging to different sources, fetching data at once from different kinds of content providers are some of other possible use cases for that feature.
*/

//: [Next: Testing](@next)
