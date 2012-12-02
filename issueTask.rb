require "plist"
require "erb"
require "zip/zip"
require "tempfile"
require "json"

class IssueTask
  @queue = :issue_processing
  
  def self.perform(authorsPlist, issueZip)
    
    authors = Plist::parse_xml(authorsPlist)
    template = ERB.new(File.read("article.html.erb"))
    begin
      issuedb = JSON.parse(File.read("issuesdb.json"))
    rescue
      issuedb = []
    end
    
    
    issue = Zip::ZipFile.open(issueZip)
    issueIndexEntry = issue.entries.find {|file| 
      (/issue[^.plist]*.plist/.match(file.name) != nil)
    }
    tempIndex = Tempfile.new("issueIndex")
    issue.extract(issueIndexEntry, tempIndex){true}
    issueIndex = Plist::parse_xml(tempIndex)
    
    issueId = issueIndex["displayIssueNumber"]
    
    issueidx = issuedb.index do |issue|
      (issue["number"] == issueId)
    end
    
    archiveIssue = nil
    
    if (issueidx != nil)
      archiveIssue = issuedb[issueidx]
      archiveIssue["articles"].clear
    else
      archiveIssue = {}
      archiveIssue["number"] = issueId
      archiveIssue["pubdate"] = issueIndex["publicationDate"]
      archiveIssue["articles"] = []
      issuedb.push archiveIssue
    end
    
    issueIndex["articles"].each {|articleInfo|
      articleTitle = articleInfo["title"]
      articleSummary = articleInfo["summary"]
      slug = articleInfo["shareURL"].split("/").last
            
      author = authors[articleInfo["authorID"]]["name"]
      authorWebsite = authors[articleInfo["authorID"]]["url"]
      
      archiveArticle = {
        "permalink" => slug,
        "title" => articleTitle,
        "summary" => articleSummary,
        "author" => author,
        "authorURL" => authorWebsite
      }
      
      archiveIssue["articles"].push archiveArticle
      
      temp = Tempfile.new(articleInfo["articleID"])
      issue.extract(articleInfo["articleID"]+".html", temp){true}
      story = File.read(temp)
      
      File.open("articles/"+issueId+"-"+slug+".html", "w") {|file|
        file.write(template.result(binding))
      }
    }
    File.open("issuesdb.json", "w") do |file|
      file.write(issuedb.to_json)
    end
    File.delete("public/index.html")
  end
end