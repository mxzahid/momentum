import Foundation

class AIService {
    static let shared = AIService()
    
    private init() {}
    
    struct AIInsight {
        var summary: String
        var nextAction: String
        var motivation: String
    }
    
    func generateInsight(for project: Project) async -> AIInsight? {
        let settings = await MainActor.run { SettingsManager.shared.settings }
        
        guard settings.enableAIInsights else {
            return nil
        }
        
        let prompt = buildPrompt(for: project)
        
        guard let response = await callOllama(
            endpoint: settings.ollamaEndpoint,
            model: settings.ollamaModel,
            prompt: prompt
        ) else {
            return nil
        }
        
        return parseResponse(response)
    }
    
    func generateProjectSummary(projects: [Project]) async -> String? {
        let settings = await MainActor.run { SettingsManager.shared.settings }
        
        guard settings.enableAIInsights else {
            return nil
        }
        
        let activeProjects = projects.filter { $0.daysSinceLastActivity <= 7 }.count
        let coolingProjects = projects.filter { $0.daysSinceLastActivity > 7 && $0.daysSinceLastActivity <= 30 }.count
        let dormantProjects = projects.filter { $0.daysSinceLastActivity > 30 }.count
        
        let prompt = """
        You are a motivational project coach. Analyze this project portfolio:
        
        Total Projects: \(projects.count)
        Active (< 7 days): \(activeProjects)
        Cooling (7-30 days): \(coolingProjects)
        Dormant (> 30 days): \(dormantProjects)
        
        Recent activity patterns:
        \(projects.prefix(5).map { "- \($0.name): last active \($0.daysSinceLastActivity) days ago" }.joined(separator: "\n"))
        
        Provide a brief 2-3 sentence insight about their work pattern and suggest one actionable focus area.
        Be encouraging but honest. Keep it under 100 words.
        """
        
        return await callOllama(
            endpoint: settings.ollamaEndpoint,
            model: settings.ollamaModel,
            prompt: prompt
        )
    }
    
    private func buildPrompt(for project: Project) -> String {
        let days = project.daysSinceLastActivity
        let commits = project.commitCount
        
        let goalsText: String
        if project.goals.isEmpty {
            goalsText = "None set"
        } else {
            let activeGoals = project.goals.filter { !$0.isCompleted }
            if activeGoals.isEmpty {
                goalsText = "All \(project.goals.count) goals completed! 🎉"
            } else {
                goalsText = activeGoals.prefix(3).map { "- \($0.text)" }.joined(separator: "\n")
            }
        }
        
        return """
        You are a project advisor. Analyze this project:
        
        Name: \(project.name)
        Last Activity: \(days) days ago
        Total Commits: \(commits)
        Status: \(project.activityStatus.rawValue)
        Goals:
        \(goalsText)
        
        Provide:
        1. A brief 1-sentence summary of the project state
        2. One specific next action they should take (be concrete)
        3. A short motivational message (1 sentence, upbeat tone)
        
        Format your response as:
        SUMMARY: [summary]
        ACTION: [next action]
        MOTIVATION: [motivation]
        
        Keep each section to one sentence. Total response under 100 words.
        """
    }
    
    private func callOllama(endpoint: String, model: String, prompt: String) async -> String? {
        guard let url = URL(string: "\(endpoint)/api/generate") else {
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "stream": false
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return nil
        }
        
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let responseText = json["response"] as? String {
                return responseText
            }
        } catch {
            print("❌ Ollama API error: \(error)")
        }
        
        return nil
    }
    
    private func parseResponse(_ response: String) -> AIInsight {
        var summary = ""
        var action = ""
        var motivation = ""
        
        let lines = response.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("SUMMARY:") {
                summary = line.replacingOccurrences(of: "SUMMARY:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("ACTION:") {
                action = line.replacingOccurrences(of: "ACTION:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("MOTIVATION:") {
                motivation = line.replacingOccurrences(of: "MOTIVATION:", with: "").trimmingCharacters(in: .whitespaces)
            }
        }
        
        return AIInsight(
            summary: summary.isEmpty ? "This project could use some attention." : summary,
            nextAction: action.isEmpty ? "Review the codebase and plan next steps." : action,
            motivation: motivation.isEmpty ? "You've got this! 🚀" : motivation
        )
    }
}

