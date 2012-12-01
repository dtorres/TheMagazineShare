require "plist"
require "erb"
require "zip/zip"
require "tempfile"

class IssueTask
  @queue = :issue_processing
  
  def self.perform(authorsPlist, issueZip)
    
    authors = Plist::parse_xml(authorsPlist)
    template = ERB.new(File.read("articleTemplate.html.erb"))
    
    issue = Zip::ZipFile.open(issueZip)
    issueIndexEntry = issue.entries.find {|file| 
      (/issue[^.plist]*.plist/.match(file.name) != nil)
    }
    tempIndex = Tempfile.new("issueIndex")
    issue.extract(issueIndexEntry, tempIndex){true}
    issueIndex = Plist::parse_xml(tempIndex)
    
    
    issueId = issueIndex["displayIssueNumber"]
    
    issueIndex["articles"].each {|articleInfo|
      articleTitle = articleInfo["title"]
      articleSummary = articleInfo["summary"]
            
      author = authors[articleInfo["authorID"]]["name"]
      authorWebsite = authors[articleInfo["authorID"]]["url"]
      
      temp = Tempfile.new(articleInfo["articleID"])
      issue.extract(articleInfo["articleID"]+".html", temp){true}
      story = File.read(temp)
      
      slug = articleInfo["shareURL"].split("/").last
      
      File.open("articles/"+issueId+"-"+slug+".html", "w") {|file|
        file.write(template.result(binding))
      }
    }
    
  end
end