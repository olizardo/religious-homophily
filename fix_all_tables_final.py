import re

# Table structures differ in number of columns.
# Wave 3: 4 cols, Pooled/Interaction: 3 cols.
def fix_table(filename, cols):
    with open(filename, 'r') as f:
        content = f.read()

    # Add Reference Category placeholders (---)
    ref_cat_Religion = "Ego: Religion (Ref: Catholic) & --- & --- & --- \\\\" if cols == 4 else "Ego: Religion (Ref: Catholic) & --- & --- \\\\"
    ref_cat_Gender = "Ego: Gender (Ref: Woman) & --- & --- & --- \\\\" if cols == 4 else "Ego: Gender (Ref: Woman) & --- & --- \\\\"

    content = content.replace("Ego: Religion (Ref: Catholic)", ref_cat_Religion)
    content = content.replace("Ego: Gender (Ref: Woman)", ref_cat_Gender)
    
    with open(filename, 'w') as f:
        f.write(content)

fix_table('Tabs/tbl-wave3-reg.tex', 4)
fix_table('Tabs/tbl-pooled-interaction-reg.tex', 3)
fix_table('Tabs/tbl-pooled-reg.tex', 2) # Oops, 2 cols? Let me check.
# Wait, let me check column counts in the files before running.
