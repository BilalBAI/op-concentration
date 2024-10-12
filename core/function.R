proposal_filter <- function(proposal_csv,proposal_times){
  library(dplyr)
  prop_address_num =  proposal_csv  %>% group_by(address) %>% summarise(number_prop= length(unique(proposal_id)))
  
  prop_address_num_filter = prop_address_num %>% filter(number_prop >= proposal_times )
  
  prop_filter = proposal_csv %>% filter(address %in% prop_address_num_filter$address)
  return(prop_filter)
}


final_voting_result <- function(voting_res_filter){
  library(dplyr)
  voting_res_filter_final = data.frame() 
  
  for (i in 1:unique(length(voting_res_filter$proposal_id))) {
    D = voting_res_filter %>% filter(proposal_id == unique(voting_res_filter$proposal_id)[i])
    if(dim(D)[1]==2){
      D_for = D %>% filter(proposal_choice=='FOR')
      D_for_p = D_for$voting_power
      D_Ag = D %>% filter(proposal_choice=='AGAINST')
      D_Ag_p = D_Ag$voting_power
      
      if (D_for_p>D_Ag_p) {
        voting_res_filter_final = rbind(voting_res_filter_final,D_for)
      } else{
        voting_res_filter_final = rbind(voting_res_filter_final,D_Ag)
      }
    }# end dim(D)[1]==2
    else{
      voting_res_filter_final = rbind(voting_res_filter_final,D)
    }
  }
  return(voting_res_filter_final)
} # end function


proposal_result_merge <- function(voting_res_filter_final,prop_filter){
  prop_filter_add = merge(voting_res_filter_final[c('proposal_id','proposal_choice')],prop_filter[c('address','proposal_id','voted_choice')],by = 'proposal_id')
  return(prop_filter_add)
}




Similar_matriix <- function(prop_filter_add, num_same_choice){
  
  library(dplyr)
  l = length(unique(prop_filter_add$address))
  M = matrix(rep(0,l^2),nrow =l )
  
  for (i in 1:l) {
    for (j in i:l) {
      token_1 = prop_filter_add %>% filter(address == unique(address)[i])
      token_1 = token_1[c('proposal_id','proposal_choice')]
      token_2 = prop_filter_add %>% filter(address == unique(address)[j])
      token_2 = token_2[c('proposal_id','proposal_choice')]
      
      M[i,j] = dim(intersect(token_1,token_2))[1]
      
    }
  }
  
  M_full = M
  
  for (i in 2:dim(M)[1]) {
    for (j in 1:(i-1)) {
      M_full[i,j] = M[j,i]
    }
  }
  
  M_tranc = M_full
  for (i in dim(M_full)[1]) {
    for (j in dim(M_full)[1]) {
      if (M_tranc[i,j]<= num_same_choice) {
        M_tranc[i,j] = 0
      }
    }
  }
  
  
  return(M_tranc)
} # end function


Community_detection <- function(M_tranc,min_mod,max_resolution){
  library(igraph)
  set.seed(1)
  # 示例相似性矩阵
  similarity_matrix <- M_tranc
  #similarity_matrix <- M_token_tranc_t
  # 创建图对象
  g <- graph_from_adjacency_matrix(similarity_matrix, mode = "undirected", weighted = TRUE, diag = FALSE)
  
  # 设置图形布局
  layout <- layout_with_fr(g)
  
  # 设置节点颜色和大小
  V(g)$color <- "skyblue"
  V(g)$size <- 1
  
  # 设置边的宽度和颜色
  E(g)$width <- E(g)$weight * 2
  E(g)$color <- "grey"
  
  
  
  # 进行Louvain社团检测
  
  ### 试图进行调优参数
  best_mod = 0
  best_res = 0
  for (i in seq(0.01,max_resolution,0.01)) {
    set.seed(1)
    community <- cluster_louvain(g,resolution = i)
    mod = modularity(community)
    if (mod>best_mod | mod>min_mod) {
      best_mod = mod
      best_res = i
    }
  }
  
  community_ <- cluster_louvain(g,resolution = best_res)
  
  # z = community$membership 
  
  # 绘制网络图，按照社团进行着色
  plot(community_, g, vertex.size = 15, vertex.label = NA, 
       edge.arrow.size = 0.5, 
       vertex.color = membership(community) + 1)
  
  Louvain_member_ = community_$membership 
  result = list(community = community_, membership = Louvain_member_)
  
  return(result)
  
} #  end function



Logistic_reg_single <- function(prop_filter_add,Louvain_member,average=TRUE){
  library(dplyr)
  # 数据类型转换
  df_ = prop_filter_add
  df_$proposal_choice_ <- ifelse(prop_filter_add$proposal_choice=='FOR',1,0) 
  df_$voted_choice_ <- ifelse(prop_filter_add$voted_choice=='FOR',1,0)
  
  address_ = unique(prop_filter_add$address)
  # define a vector to store the effect of everyone
  log_eff = rep(0,length(unique(prop_filter_add$address)))
  for (i in 1:length(log_eff)) {
    df = df_ %>% filter(address==address_[i])
    log_model <- glm(proposal_choice_ ~ voted_choice_, data = df, family = binomial)
    log_eff[i]=log_model$coefficients[2]
    
  }
  
  if (average==TRUE) {
    # give same effect to the elements in the same group
    ad_log_eff = rep(0,length(log_eff))
    
    for (i in 1:max(Louvain_member)) {
      if (sum(Louvain_member==i)==1) {
        ad_log_eff[i]=mean(log_eff[i],na.rm = T)
      }
      else{
        a = log_eff[Louvain_member==i]
        a = a[!is.na(a)]
        ad_log_eff[Louvain_member==i] = rep(mean(a,na.rm = TRUE),sum(Louvain_member==i))
      }
    }
    
    #ad_log_eff=ad_log_eff[!is.nan(ad_log_eff)]
    
    return(ad_log_eff)
  } #end if
  else{
    
    return(log_eff)
  }
  
  
  
} # end function


Logistic_reg_multiple <- function(...){
  library(dplyr)
  dfs = list(...)
  # 提取所有数据框中的address列，并找到共同的address
  common_addresses <- Reduce(intersect, lapply(dfs, function(df) unique(df$address)))
  
  # 根据共同的address筛选出每个数据框中的对应行
  filtered_dfs <- lapply(dfs, function(df) filter(df, address %in% common_addresses))
  
  # 将所有数据框的筛选结果合并在一起
  combined_df <- bind_rows(filtered_dfs)
  # 转换数据类型
  combined_df$proposal_choice_ <- ifelse(combined_df$proposal_choice=='FOR',1,0) 
  combined_df$voted_choice_ <- ifelse(combined_df$voted_choice=='FOR',1,0)
  
  log_eff_both = rep(0,length(common_addresses))
  for (i in 1:length(log_eff_both)) {
    dff = combined_df %>% filter(address==common_addresses[i])
    
    log_model <- glm(proposal_choice_ ~ voted_choice_, data = dff, family = binomial)
    log_eff_both[i]=log_model$coefficients[2]
    
  } #end for
  
  return(log_eff_both)
  
}



CT_Logistic_reg_single <- function(prop_filter,Louvain_member,average=TRUE){
  library(dplyr)
  l=length(unique(prop_filter$address))
  log_eff_rev = rep(0,l)
  
  #在转换时,还是一个一个转换
  for (i in 1:l) {
    
    prop_filter_rev =prop_filter
    address_ = unique(prop_filter$address)
    prop_filter_rev$voted_choice[prop_filter_rev$address==address_[i]] =   ifelse(prop_filter_rev$voted_choice[prop_filter_rev$address==address_[i]] == 'FOR','AGAINST','FOR')
    ###
    voting_res_rev = prop_filter_rev %>% group_by(proposal_id)  %>% summarise(
      For_result = sum(voting_power[voted_choice=='FOR']),
      Against_result = sum(voting_power[voted_choice=='AGAINST']))
    
    voting_res_rev = voting_res_rev %>% mutate(
      proposal_choice = ifelse(For_result>Against_result,'FOR','AGAINST'))
    #目前得到新的proposal结果：voting_res_rev
    
    
    #现在合并数据
    prop_filter_rev_add = merge(voting_res_rev[c('proposal_id','proposal_choice')],prop_filter_rev[c('address','proposal_id','voted_choice')],by = 'proposal_id')
    #转换数据类型
    df_ = prop_filter_rev_add
    df_$proposal_choice_ <- ifelse(prop_filter_rev_add$proposal_choice=='FOR',1,0) 
    df_$voted_choice_ <- ifelse(prop_filter_rev_add$voted_choice=='FOR',1,0) 
    
    
    df = df_[df_$address==address_[i],]
    log_model <- glm(proposal_choice_ ~ voted_choice_, data = df, family = binomial)
    log_eff_rev[i]=log_model$coefficients[2]
    
    
    
  } # end for
  
  if(average==TRUE) {
    # give same effect to the elements in the same group
    ad_log_eff_rev = rep(0,length(log_eff_rev))
    
    for (i in 1:max(Louvain_member)) {
      if (sum(Louvain_member==i)==1) {
        ad_log_eff_rev[i]=mean(log_eff_rev[i],na.rm = T)
      }
      else{
        b = log_eff_rev[Louvain_member==i]
        b = b[!is.na(b)]
        ad_log_eff_rev[Louvain_member==i] = rep(mean(b,na.rm = TRUE),sum(Louvain_member==i))
      }
      
    }
    return(ad_log_eff_rev)
    
  } #end if
  else{
    return(log_eff_rev)
  }
  
} # end function



CT_fun <- function(prop_filter,address_both,i){
  ## token
  prop_filter_rev =prop_filter
  prop_filter_rev$voted_choice[prop_filter_rev$address==address_both[i]] =   ifelse(prop_filter_rev$voted_choice[prop_filter_rev$address==address_both[i]] == 'FOR','AGAINST','FOR')
  ###
  voting_res_rev = prop_filter_rev %>% group_by(proposal_id)  %>% summarise(
    For_result = sum(voting_power[voted_choice=='FOR']),
    Against_result = sum(voting_power[voted_choice=='AGAINST']))
  
  voting_res_rev = voting_res_rev %>% mutate(
    proposal_choice = ifelse(For_result>Against_result,'FOR','AGAINST'))
  #目前得到新的proposal结果：voting_res_rev
  
  
  
  #现在合并数据
  prop_filter_rev_add = merge(voting_res_rev[c('proposal_id','proposal_choice')],prop_filter_rev[c('address','proposal_id','voted_choice')],by = 'proposal_id')
  #转换数据类型
  df_ = prop_filter_rev_add
  df_$proposal_choice_ <- ifelse(prop_filter_rev_add$proposal_choice=='FOR',1,0) 
  df_$voted_choice_ <- ifelse(prop_filter_rev_add$voted_choice=='FOR',1,0) 
  
  
  df1 = df_[df_$address==address_both[i],]
  
  return(df1)
}


CT_Logistic_reg_multiple <- function(...){
  library(dplyr)
  dfs = list(...)
  # 提取所有数据框中的address列，并找到共同的address
  common_addresses <- Reduce(intersect, lapply(dfs, function(df) unique(df$address)))
  
  # 根据共同的address筛选出每个数据框中的对应行
  filtered_dfs <- lapply(dfs, function(df) filter(df, address %in% common_addresses))
  
  # 将所有数据框的筛选结果合并在一起
  combined_df <- bind_rows(filtered_dfs)
  
  log_eff_both_rev = rep(0,length(common_addresses))
  for (i in 1:length(common_addresses)) {
    CT_dfs <- lapply(dfs, function(df) CT_fun(df,common_addresses,i))
    combined_CT_df <- bind_rows(CT_dfs)
    
    log_model <- glm(proposal_choice_ ~ voted_choice_, data = combined_CT_df, family = binomial)
    log_eff_both_rev[i]=log_model$coefficients[2]
  }
  
  
  return(log_eff_both_rev)
  
}


Centrality_statistics <- function(data) {
  # 加载包
  library(entropy)
  library(moments)
  library(ineq)
  #library(DescTools)
  # 检查输入是否为数值型向量
  if (!is.numeric(data)) {
    stop("input has to be the numeric vector")
  }
  data = data[!is.na(data)]
  data = data[!is.nan(data)]
  # 计算方差 (Variance)
  variance_value <- var(data)
  
  # 计算偏度 (Skewness)
  skewness_value <- skewness(data)
  
  # 计算峰度 (Kurtosis)
  kurtosis_value <- kurtosis(data)
  
  # 计算 Gini 系数 (Gini Coefficient)
  gini_value <- Gini(data)
  
  # 计算赫芬达尔-赫希曼指数 (Herfindahl-Hirschman Index, HHI)
  hhi_value <- sum((table(data) / length(data))^2)
  
  # 计算熵 (Entropy)
  entropy_value <- entropy(table(data))
  
  #计算变异系数
  CV <- sd(data)/mean(data)
  
  # 创建数据框来存放这些统计指标
  result <- data.frame(
    Statistic = c("Variance", "Skewness", "Kurtosis", "Gini Coefficient", "Herfindahl-Hirschman Index", "Entropy","CV"),
    Value = c(variance_value, skewness_value, kurtosis_value, gini_value, hhi_value, entropy_value,CV)
  )
  
  return(result)
}

