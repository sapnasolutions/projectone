class FrontController < ApplicationController

  hobo_controller

  def index; end

  def summary
    if !current_user.administrator?
      redirect_to user_login_path
    end
  end

  def search
    if params[:query]
      site_search(params[:query])
    end
  end
  
  def site_search(query) 
       results = Client.all.select{ |c| c.name.to_s.format_research.include? query.to_s.format_research or  c.raison_social.to_s.format_research.include? query.to_s.format_research}
	   results = results + Installation.all.select{ |i| i.code_acces_distant.to_s.format_research.include? query.to_s.format_research}
	   # ModelB.find(:all, :conditions => ...) 
       all_results = results.select { |r| r.viewable_by?(current_user) } 
       if all_results.empty? 
         render :text => "<p>"+ t(:"hobo.live_search.no_results", 
:default=>["Your search returned no matches."]) + "</p>" 
       else 
         render_tags(all_results, :search_card, :for_type => true) 
       end 
   end 

end
