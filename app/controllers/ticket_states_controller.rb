# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class TicketStatesController < ApplicationController
  before_filter :authentication_check

  # GET /ticket_states
  def index
    model_index_render(Ticket::State, params)
  end

  # GET /ticket_states/1
  def show
    model_show_render(Ticket::State, params)
  end

  # POST /ticket_states
  def create
    return if deny_if_not_role('Admin')
    model_create_render(Ticket::State, params)
  end

  # PUT /ticket_states/1
  def update
    return if deny_if_not_role('Admin')
    model_update_render(Ticket::State, params)
  end

  # DELETE /ticket_states/1
  def destroy
    return if deny_if_not_role('Admin')
    model_destory_render(Ticket::State, params)
  end
end
