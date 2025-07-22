# Admin Quick Reference Guide

## Common Tasks

### Route Management

#### **Route Assignment Monitoring**
1. Check Today tab for worker assignments
2. View route completion status
3. Monitor maintenance progress
4. Review route optimization

#### **Route Map Features**
- **Green Pinpoints**: Maintained pools (excluded from route)
- **Red Pinpoints**: Pools needing maintenance (included in route)
- **Route Optimization**: Only considers non-maintained pools
- **Real-Time Updates**: Maintenance status checked automatically

#### **Worker Dashboard Today Tab**
- Shows current account's active route assignment for today
- Displays completion status (completed vs pending pools)
- Route-based pool loading from actual assignments
- Integration with route map functionality

### Company Management

#### **Approve New Company**
1. Go to Companies List
2. Find company with "Pending" status
3. Click "Approve" button
4. Owner automatically becomes Admin

#### **Edit Company Details**
1. Click ⋮ menu next to company
2. Select "Edit"
3. Modify information
4. Click "Save Changes"

#### **Suspend Company**
1. Click ⋮ menu next to company
2. Select "Suspend"
3. Enter reason
4. Confirm action

### User Management

#### **Change User Role**
1. Go to Users section
2. Find user in list
3. Click "Edit"
4. Change role dropdown
5. Save changes

#### **Reset User Password**
1. User must use "Forgot Password"
2. Check email for reset link
3. Create new password

### System Issues

#### **User Cannot Login**
- Check if email is verified
- Verify user role is correct
- Check if account is suspended
- Clear browser cache

#### **Company Not Showing**
- Check company status
- Verify user has correct permissions
- Refresh page
- Check Firestore rules

#### **Data Not Loading**
- Check internet connection
- Verify Firebase configuration
- Check browser console for errors
- Clear browser cache

## Emergency Procedures

### **System Down**
1. Check Firebase status page
2. Verify application URL
3. Check browser compatibility
4. Contact IT support

### **Data Loss**
1. Check Firestore backup
2. Review recent changes
3. Contact database administrator
4. Document incident

### **Security Breach**
1. Immediately suspend affected accounts
2. Change admin passwords
3. Review access logs
4. Contact security team

## Contact Information

### **Technical Support**
- Email: support@shinningpools.com
- Phone: (555) 123-4567
- Hours: 8 AM - 6 PM EST

### **Emergency Contacts**
- IT Director: (555) 123-4568
- Database Admin: (555) 123-4569
- Security Team: (555) 123-4570

## Keyboard Shortcuts

- **Ctrl + F**: Search
- **Ctrl + R**: Refresh
- **Esc**: Close dialogs
- **F5**: Hard refresh

## Status Codes

- 🟢 **Active**: Normal operation
- 🟡 **Pending**: Awaiting action
- 🔴 **Suspended**: Temporarily disabled
- ⚫ **Inactive**: Not in use

## Maintenance Lists (Novedad 2025)
- **Admins**: En la pestaña de Piscinas, verás la lista "Mantenimiento Reciente (Últimos 20)" con filtros avanzados.
- **Trabajadores**: En la pestaña de Reportes, al final, verás tu lista de mantenimientos recientes.

## Firestore Index Error (Solución Rápida)
- Si ves un error de índice en la app, copia el enlace del mensaje y ábrelo en tu navegador para crear el índice en Firebase.
- Si el enlace está roto, consulta la documentación o contacta soporte para los pasos manuales.

---

*Last Updated: June 2025* 