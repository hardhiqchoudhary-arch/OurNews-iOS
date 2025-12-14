# OurNews - Social News Platform

A comprehensive iOS news application that combines real-time news aggregation with social networking features, built with SwiftUI and Firebase.

## 📱 Overview

OurNews is a modern news application that reimagines how users consume and interact with news content. By integrating social features with intelligent content discovery, OurNews creates an engaging platform where users can stay informed while connecting with others who share their interests.

## ✨ Features

### News Aggregation
- **Real-time News Feed**: Aggregates news from multiple reputable sources
- **Smart Categorization**: NLP-powered keyword extraction automatically categorizes articles
- **Personalized Recommendations**: Tailored news suggestions based on user interests and reading history
- **Multi-source Integration**: Curated content from diverse news outlets

### Social Networking
- **User Profiles**: Customizable profiles with reading preferences and interests
- **Follow System**: Connect with users who share similar news interests
- **Article Sharing**: Share interesting articles with followers and groups
- **Group Discussions**: Create and join topic-based discussion groups
- **Comments & Interactions**: Engage in conversations around news articles

### Content Discovery
- **Keyword Extraction**: Advanced NLP algorithms identify key topics in articles
- **Topic-based Filtering**: Browse news by categories and trending topics
- **Search Functionality**: Find articles by keywords, topics, or sources
- **Bookmarks**: Save articles for later reading

## 🛠️ Tech Stack

- **Frontend**: SwiftUI
- **Backend**: Firebase
  - Firebase Authentication (User management)
  - Cloud Firestore (Real-time database)
  - Firebase Storage (Media storage)
  - Cloud Functions (Backend logic)
- **APIs**: News APIs for content aggregation
- **NLP**: Natural Language Processing for keyword extraction and categorization
- **Architecture**: MVVM (Model-View-ViewModel)

## 🏗️ Architecture

```
OurNews/
├── Models/
│   ├── Article.swift
│   ├── User.swift
│   ├── Group.swift
│   └── Comment.swift
├── Views/
│   ├── Home/
│   ├── Profile/
│   ├── Groups/
│   ├── Article/
│   └── Authentication/
├── ViewModels/
│   ├── NewsViewModel.swift
│   ├── UserViewModel.swift
│   ├── GroupViewModel.swift
│   └── AuthViewModel.swift
├── Services/
│   ├── FirebaseService.swift
│   ├── NewsAPIService.swift
│   └── NLPService.swift
└── Utilities/
    ├── Extensions/
    └── Constants/
```

## 🚀 Getting Started

### Prerequisites
- Xcode 14.0 or later
- iOS 16.0 or later
- CocoaPods or Swift Package Manager
- Firebase account

### Installation

1. Clone the repository
```bash
git clone https://github.com/hardhiqchoudhary-arch/OurNews.git
cd OurNews
```

2. Install dependencies
```bash
# If using CocoaPods
pod install

# If using Swift Package Manager
# Dependencies will be resolved automatically in Xcode
```

3. Configure Firebase
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist`
   - Add it to the project root directory
   - Enable Authentication, Firestore, and Storage in Firebase Console

4. Add your News API key
   - Obtain API keys from your news sources
   - Add to `Config.swift` or environment variables

5. Open the project
```bash
open OurNews.xcworkspace  # if using CocoaPods
# or
open OurNews.xcodeproj     # if using SPM
```

6. Build and run
   - Select your target device or simulator
   - Press `Cmd + R` to build and run

## 📖 Key Functionalities

### Authentication
- Email/password authentication
- Social sign-in options
- Secure user session management
- Password reset functionality

### News Feed
```swift
// Example: Fetching personalized news
func fetchPersonalizedNews() async {
    let userInterests = await getUserInterests()
    let news = await newsService.fetchNews(for: userInterests)
    articles = processWithNLP(news)
}
```

### Social Features
```swift
// Example: Following a user
func followUser(_ userId: String) async {
    await FirebaseService.shared.addFollower(userId)
    await updateFollowingList()
}
```

### NLP Processing
- Automatic keyword extraction from article content
- Topic classification using machine learning
- Sentiment analysis for article categorization
- Trending topics identification

## 🎯 Use Cases

1. **News Enthusiast**: Stay updated with personalized news from multiple sources
2. **Discussion Groups**: Join communities discussing specific topics (politics, tech, sports)
3. **Content Curator**: Share interesting articles with followers
4. **Trend Tracker**: Follow trending topics and emerging stories


## 🔮 Future Enhancements

- [ ] Push notifications for breaking news and social interactions
- [ ] Offline reading mode with article caching
- [ ] Advanced analytics dashboard for reading habits
- [ ] Integration with more news sources and languages
- [ ] Video news content support
- [ ] Dark mode optimization
- [ ] iPad and Mac Catalyst support
- [ ] AI-powered article summarization
- [ ] Podcast integration

## 🧪 Testing

```bash
# Run unit tests
cmd + U in Xcode

# Run UI tests
# Select UI Test target and run
```

## 📊 Performance Optimizations

- Lazy loading for news feed
- Image caching and optimization
- Efficient Firebase query optimization
- Background fetch for new content
- Memory management for large datasets

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 👨‍💻 Author

**Hardhiq Choudhary**
- GitHub: [@hardhiqchoudhary-arch](https://github.com/hardhiqchoudhary-arch)
- LinkedIn: [Hardhiq Choudhary](https://www.linkedin.com/in/hardhiq-choudhary-a28b56158/)
- Email: hardhiq.choudhary@gwmail.gwu.edu

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- News API providers for content
- SwiftUI community for inspiration and resources
- Open-source NLP libraries

**Note**: This project was developed as part of academic coursework at George Washington University (September 2025 - December 2025).


## 📞 Support

For support, email hardhiq.choudhary@gwmail.gwu.edu or open an issue in this repository.
