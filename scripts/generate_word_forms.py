#!/usr/bin/env python3
"""
从Web端的word_forms_map.json生成iOS用的简化版JSON
只保留必要的映射关系，减小文件体积
"""

import json
import sys
from pathlib import Path

def main():
    # 读取Web端的词形映射数据
    web_data_path = Path(__file__).parent.parent.parent / "word_learning_app" / "data" / "word_forms_map.json"
    
    if not web_data_path.exists():
        print(f"❌ 找不到文件: {web_data_path}")
        sys.exit(1)
    
    with open(web_data_path, 'r', encoding='utf-8') as f:
        web_data = json.load(f)
    
    # 转换为简化格式
    ios_data = {}
    
    for word, info in web_data.items():
        # 只保留非原形的词
        if not info.get('is_original', True):
            original = info.get('original', word)
            form_type = info.get('input_form_type', 'variant')
            
            # 映射类型名称
            type_mapping = {
                '复数': 'plural',
                '过去式': 'past',
                '过去分词': 'past_participle',
                '现在分词': 'present_participle',
                '第三人称单数': 'third_person',
                '第三人称': 'third_person',
                '变体': 'variant',
                'past_participle': 'past_participle',
                'present_participle': 'present_participle',
                'third_person': 'third_person',
            }
            
            mapped_type = type_mapping.get(form_type, 'variant')
            
            ios_data[word] = {
                "original": original,
                "type": mapped_type
            }
    
    # 输出到iOS Resources目录
    output_path = Path(__file__).parent.parent / "WordLearningApp" / "Resources" / "word_forms_map.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(ios_data, f, ensure_ascii=False, indent=2)
    
    print(f"✅ 成功生成 {len(ios_data)} 个词形映射")
    print(f"📁 输出文件: {output_path}")
    
    # 统计信息
    type_counts = {}
    for info in ios_data.values():
        t = info['type']
        type_counts[t] = type_counts.get(t, 0) + 1
    
    print("\n📊 类型统计:")
    for t, count in sorted(type_counts.items(), key=lambda x: -x[1]):
        print(f"  {t}: {count}")

if __name__ == '__main__':
    main()
