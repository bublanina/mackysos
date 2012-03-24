# -*- encoding : utf-8 -*-
class RealValuesController < ApplicationController
  # GET /real_values
  # GET /real_values.json
  def index
    @real_values = RealValue.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @real_values }
    end
  end

  # GET /real_values/1
  # GET /real_values/1.json
  def show
    @real_value = RealValue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @real_value }
    end
  end

  # GET /real_values/new
  # GET /real_values/new.json
  def new
    @real_value = RealValue.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @real_value }
    end
  end

  # GET /real_values/1/edit
  def edit
    @real_value = RealValue.find(params[:id])
  end

  # POST /real_values
  # POST /real_values.json
  def create
    @real_value = RealValue.new(params[:real_value])

    respond_to do |format|
      if @real_value.save
        format.html { redirect_to @real_value, notice: 'Real value was successfully created.' }
        format.json { render json: @real_value, status: :created, location: @real_value }
      else
        format.html { render action: "new" }
        format.json { render json: @real_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /real_values/1
  # PUT /real_values/1.json
  def update
    @real_value = RealValue.find(params[:id])

    respond_to do |format|
      if @real_value.update_attributes(params[:real_value])
        format.html { redirect_to @real_value, notice: 'Real value was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @real_value.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /real_values/1
  # DELETE /real_values/1.json
  def destroy
    @real_value = RealValue.find(params[:id])
    @real_value.destroy

    respond_to do |format|
      format.html { redirect_to real_values_url }
      format.json { head :ok }
    end
  end
end
