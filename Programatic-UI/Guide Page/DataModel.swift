import Foundation

struct GuideItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let phone: String
    let address: String
    let hours: String
    let rating: Double

    struct DataModel {
        static let clinics = [
            GuideItem(title: "Apollo Clinic", imageName: "Clinic1", phone: "+91 44 2829 0200", address: "No. 21, Greams Lane, Off Greams Road, Chennai", hours: "Mon-Sat 8am-8pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Cloudnine Hospital", imageName: "Clinic2", phone: "+91 44 4600 8000", address: "No. 6, Cenotaph Road, Teynampet, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Dr. Mehta's Hospitals", imageName: "Clinic3", phone: "+91 44 2811 6698", address: "No. 4, Shafee Mohammed Road, Nungambakkam, Chennai", hours: "Mon-Sun 9am-6pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Madras Medical Mission", imageName: "Clinic4", phone: "+91 44 2829 1283", address: "No. 4, 3rd Cross Street, Raja Annamalaipuram, Chennai", hours: "Mon-Sat 8am-5pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "SIMS Hospital", imageName: "Clinic5", phone: "+91 44 4860 0000", address: "No. 1, Jawaharlal Nehru Road, Madipakkam, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0))
        ]
        
        static let hotels = [
            GuideItem(title: "Taj Coromandel", imageName: "Hotel1", phone: "+91 44 6600 1414", address: "Navar Street, Teynampet, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Marriott Chennai", imageName: "Hotel2", phone: "+91 44 6710 5000", address: "No. 523, Avanashi Road, Coimbatore", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "ITC Grand Chola", imageName: "Hotel3", phone: "+91 44 2220 0000", address: "No. 63, Mount Road, Guindy, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "The Park Chennai", imageName: "Hotel4", phone: "+91 44 4214 4000", address: "601, Anna Salai, Thousand Lights, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Trident Chennai", imageName: "Hotel5", phone: "+91 44 6631 5000", address: "1/24, GPO Road, Rajaji Salai, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0))
        ]
        
        static let hospitals = [
            GuideItem(title: "Apollo Hospitals", imageName: "Hospital1", phone: "+91 44 2829 8000", address: "No. 21, Greams Lane, Thousand Lights, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Fortis Malar Hospital", imageName: "Hospital2", phone: "+91 44 4613 4000", address: "No. 52, 1st Main Road, Raja Annamalaipuram, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Sri Ramachandra Hospital", imageName: "Hospital3", phone: "+91 44 2476 2911", address: "No. 1, Ramachandra Nagar, Porur, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Gleneagles Global Hospital", imageName: "Hospital4", phone: "+91 44 4244 4000", address: "No. 43, New No. 14, Dr. Radhakrishnan Salai, Mylapore, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "MIOT International Hospital", imageName: "Hospital5", phone: "+91 44 4424 7333", address: "No. 183, Rajiv Gandhi Salai, Kottivakkam, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0))
        ]
        
        static let pharmacies = [
            GuideItem(title: "Apollo Pharmacy", imageName: "Pharmacy1", phone: "+91 44 4398 8888", address: "No. 100, Anna Salai, Thousand Lights, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "MedPlus Pharmacy", imageName: "Pharmacy2", phone: "+91 44 4344 8000", address: "No. 55, Luz Church Road, Mylapore, Chennai", hours: "Mon-Sat 7am-10pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Guardian Pharmacy", imageName: "Pharmacy3", phone: "+91 44 4858 5858", address: "No. 22, Cathedral Road, Gopalapuram, Chennai", hours: "Mon-Sun 8am-9pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Aegean Pharmacy", imageName: "Pharmacy4", phone: "+91 44 4205 9999", address: "No. 18, Cenotaph Road, Teynampet, Chennai", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Sathya Medical Store", imageName: "Pharmacy5", phone: "+91 44 2834 5566", address: "No. 7, Nungambakkam High Road, Nungambakkam, Chennai", hours: "Mon-Sat 9am-8pm", rating: Double.random(in: 3.0...5.0))
        ]
    }
}
