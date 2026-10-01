import os

def strip_conflicts(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()
    
    out_lines = []
    for line in lines:
        if line.startswith('<<<<<<< HEAD') or line.startswith('=======') or line.startswith('>>>>>>> origin/dev-yuthika'):
            continue
        out_lines.append(line)
        
    with open(filepath, 'w') as f:
        f.writelines(out_lines)

strip_conflicts('C:/Users/User/Desktop/ECOLOOP/backend/Migrations/EcoLoopDbContextModelSnapshot.cs')
