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
            GuideItem(title: "Clinic A", imageName: "Clinic1", phone: "123-456-7890", address: "123 Health St.", hours: "Mon-Fri 9am-5pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Clinic B", imageName: "Clinic2", phone: "987-654-3210", address: "456 Care Ave.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Clinic C", imageName: "Clinic3", phone: "555-123-4567", address: "789 Well Blvd.", hours: "Mon-Sun 8am-8pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Clinic D", imageName: "Clinic4", phone: "444-555-6666", address: "321 Heal Rd.", hours: "Mon-Fri 10am-6pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Clinic E", imageName: "Clinic5", phone: "333-777-8888", address: "654 Health St.", hours: "Mon-Sat 9am-5pm", rating: Double.random(in: 3.0...5.0))
        ]
        static let hotels = [
            GuideItem(title: "Hotel X", imageName: "Hotel1", phone: "888-123-4567", address: "123 Beachside Dr.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hotel Y", imageName: "Hotel2", phone: "777-321-4321", address: "456 City Center Blvd.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hotel Z", imageName: "Hotel3", phone: "999-456-7890", address: "789 Elegance St.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hotel Y", imageName: "Hotel4", phone: "222-111-3333", address: "321 Family Dr.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hotel Z", imageName: "Hotel5", phone: "666-555-4444", address: "654 Poolside Ln.", hours: "24/7", rating: Double.random(in: 3.0...5.0))
        ]
        static let hospitals = [
            GuideItem(title: "Hospital 1", imageName: "Hospital1", phone: "111-222-3333", address: "123 Emergency Rd.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hospital 2", imageName: "Hospital2", phone: "444-555-6666", address: "456 Heart St.", hours: "Mon-Sun 9am-9pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hospital 3", imageName: "Hospital3", phone: "777-888-9999", address: "789 Technology Ave.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hospital 2", imageName: "Hospital4", phone: "333-444-5555", address: "321 Surgery Ln.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Hospital 3", imageName: "Hospital5", phone: "222-333-4444", address: "654 Trauma Blvd.", hours: "24/7", rating: Double.random(in: 3.0...5.0))
        ]
        static let pharmacies = [
            GuideItem(title: "Pharmacy P", imageName: "Pharmacy1", phone: "111-222-1234", address: "123 Main St.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Pharmacy Q", imageName: "Pharmacy2", phone: "333-444-5556", address: "456 Green Way.", hours: "Mon-Sat 8am-10pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Pharmacy R", imageName: "Pharmacy3", phone: "777-888-9990", address: "789 Save Blvd.", hours: "Mon-Fri 9am-6pm", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Pharmacy Q", imageName: "Pharmacy4", phone: "222-333-4567", address: "321 Health Rd.", hours: "24/7", rating: Double.random(in: 3.0...5.0)),
            GuideItem(title: "Pharmacy R", imageName: "Pharmacy5", phone: "444-555-6789", address: "654 Consult St.", hours: "Mon-Sat 9am-5pm", rating: Double.random(in: 3.0...5.0))
        ]
    }
}
