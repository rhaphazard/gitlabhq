class IssuesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :project 
  before_filter :issue, :only => [:edit, :update, :destroy, :show]

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_read_issue!
  before_filter :authorize_write_issue!, :only => [:new, :create, :close, :edit, :update, :sort] 

  respond_to :js

  def index
    @issues = case params[:f].to_i
              when 1 then @project.issues.all
              when 2 then @project.issues.closed
              when 3 then @project.issues.opened.assigned(current_user)
              else @project.issues.opened
              end

    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  def new
    @issue = @project.issues.new
    respond_with(@issue)
  end

  def edit
    respond_with(@issue)
  end

  def show
    @notes = @issue.notes
    @note = @project.notes.new(:noteable => @issue)
  end

  def create
    @issue = @project.issues.new(params[:issue])
    @issue.author = current_user
    if @issue.save
      Notify.new_issue_email(@issue).deliver
    end

    respond_with(@issue)
  end

  def update
    @issue.update_attributes(params[:issue])

    respond_to do |format|
      format.js
      format.html { redirect_to [@project, @issue]}
    end
  end


  def destroy
    return access_denied! unless can?(current_user, :admin_issue, @issue)

    @issue.destroy

    respond_to do |format|
      format.js { render :nothing => true }  
    end
  end

  def sort
    @issues = @project.issues.where(:id => params['issue'])
    @issues.each do |issue|
      issue.position = params['issue'].index(issue.id.to_s) + 1
      issue.save
    end

    render :nothing => true
  end

  protected 

  def issue
    @issue ||= @project.issues.find(params[:id])
  end
end
