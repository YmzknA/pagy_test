class VerificationController < ApplicationController
  include Pagy::Backend

  # 各手法の最もシンプルな実装で、実際のクエリを確認
  
  def pagy_standard_simple
    @step_log = []
    
    @step_log << "Step 1: Before pagy() call - #{Time.current}"
    @pagy, @articles = pagy(Article.order(:id), items: 10, page: 1)
    @step_log << "Step 2: After pagy() call - #{Time.current}"
    @step_log << "Articles class: #{@articles.class}"
    @step_log << "Articles loaded?: #{@articles.respond_to?(:loaded?) ? @articles.loaded? : 'N/A'}"
    
    @step_log << "Step 3: Before articles.to_a call - #{Time.current}"
    @articles_array = @articles.to_a
    @step_log << "Step 4: After articles.to_a call - #{Time.current}"
    @step_log << "Result count: #{@articles_array.count}"
  end

  def pagy_countless_simple
    @step_log = []
    
    @step_log << "Step 1: Before pagy_countless() call - #{Time.current}"
    @pagy, @articles = pagy_countless(Article.order(:id), items: 10, page: 1)
    @step_log << "Step 2: After pagy_countless() call - #{Time.current}"
    @step_log << "Articles class: #{@articles.class}"
    @step_log << "Articles loaded?: #{@articles.respond_to?(:loaded?) ? @articles.loaded? : 'N/A'}"
    
    @step_log << "Step 3: Before articles.to_a call - #{Time.current}"
    @articles_array = @articles.to_a
    @step_log << "Step 4: After articles.to_a call - #{Time.current}"
    @step_log << "Result count: #{@articles_array.count}"
  end

  def kaminari_standard_simple
    @step_log = []
    
    @step_log << "Step 1: Before page() call - #{Time.current}"
    @articles = Article.order(:id).page(1).per(10)
    @step_log << "Step 2: After page() call - #{Time.current}"
    @step_log << "Articles class: #{@articles.class}"
    @step_log << "Articles loaded?: #{@articles.respond_to?(:loaded?) ? @articles.loaded? : 'N/A'}"
    
    @step_log << "Step 3: Before articles.to_a call - #{Time.current}"
    @articles_array = @articles.to_a
    @step_log << "Step 4: After articles.to_a call - #{Time.current}"
    @step_log << "Result count: #{@articles_array.count}"
    
    @step_log << "Step 5: Before total_count call - #{Time.current}"
    @total_count = @articles.total_count
    @step_log << "Step 6: After total_count call - #{Time.current}"
    @step_log << "Total count: #{@total_count}"
  end

  def kaminari_without_count_simple
    @step_log = []
    
    @step_log << "Step 1: Before without_count() call - #{Time.current}"
    @articles = Article.order(:id).page(1).per(10).without_count
    @step_log << "Step 2: After without_count() call - #{Time.current}"
    @step_log << "Articles class: #{@articles.class}"
    @step_log << "Articles loaded?: #{@articles.respond_to?(:loaded?) ? @articles.loaded? : 'N/A'}"
    
    @step_log << "Step 3: Before articles.to_a call - #{Time.current}"
    @articles_array = @articles.to_a
    @step_log << "Step 4: After articles.to_a call - #{Time.current}"
    @step_log << "Result count: #{@articles_array.count}"
  end
end