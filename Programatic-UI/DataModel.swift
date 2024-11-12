import Foundation

struct GuideItem: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let description: String
}

struct DataModel {
    static let clinics = [
        GuideItem(title: "Clinic A", imageName: "Clinic1", description: "A modern clinic with experienced staff."),
        GuideItem(title: "Clinic B", imageName: "Clinic2", description: "Specialized in family medicine and pediatrics."),
        GuideItem(title: "Clinic C", imageName: "Clinic3", description: "24/7 clinic with emergency services."),
        GuideItem(title: "Clinic D", imageName: "Clinic4", description: "Offers a wide range of outpatient services."),
        GuideItem(title: "Clinic E", imageName: "Clinic5", description: "Known for its orthopedic department.")
    ]

    static let hotels = [
        GuideItem(title: "Hotel X", imageName: "Hotel1", description: "A luxury hotel with a beautiful sea view."),
        GuideItem(title: "Hotel Y", imageName: "Hotel2", description: "Affordable hotel located in the city center."),
        GuideItem(title: "Hotel Z", imageName: "Hotel3", description: "Boutique hotel with elegant decor."),
        GuideItem(title: "Hotel Y", imageName: "Hotel4", description: "Perfect for family vacations and gatherings."),
        GuideItem(title: "Hotel Z", imageName: "Hotel5", description: "Modern amenities with a rooftop pool.")
    ]

    static let hospitals = [
        GuideItem(title: "Hospital 1", imageName: "Hospital1", description: "A multi-specialty hospital with ICU services."),
        GuideItem(title: "Hospital 2", imageName: "Hospital2", description: "Famous for its cardiology department."),
        GuideItem(title: "Hospital 3", imageName: "Hospital3", description: "Equipped with the latest medical technology."),
        GuideItem(title: "Hospital 2", imageName: "Hospital4", description: "Provides top-notch surgical services."),
        GuideItem(title: "Hospital 3", imageName: "Hospital5", description: "24/7 emergency and trauma center.")
    ]

    static let pharmacies = [
        GuideItem(title: "Pharmacy P", imageName: "Pharmacy1", description: "Open 24/7 with home delivery services."),
        GuideItem(title: "Pharmacy Q", imageName: "Pharmacy2", description: "Known for its range of organic products."),
        GuideItem(title: "Pharmacy R", imageName: "Pharmacy3", description: "Discounts available on bulk purchases."),
        GuideItem(title: "Pharmacy Q", imageName: "Pharmacy4", description: "Conveniently located near the city hospital."),
        GuideItem(title: "Pharmacy R", imageName: "Pharmacy5", description: "Offers consultations with pharmacists.")
    ]
}
